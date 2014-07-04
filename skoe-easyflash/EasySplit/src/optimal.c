/*
 * Copyright (c) 2002 - 2007 Magnus Lind.
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software.
 *
 * Permission is granted to anyone to use this software, alter it and re-
 * distribute it freely for any non-commercial, non-profit purpose subject to
 * the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must not
 *   claim that you wrote the original software. If you use this software in a
 *   product, an acknowledgment in the product documentation would be
 *   appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must not
 *   be misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any distribution.
 *
 *   4. The names of this software and/or it's copyright holders may not be
 *   used to endorse or promote products derived from this software without
 *   specific prior written permission.
 *
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "log.h"
#include "search.h"
#include "radix.h"
#include "chunkpool.h"
#include "optimal.h"

struct _interval_node {
    int start;
    int score;
    struct _interval_node *next;
    signed char prefix;
    signed char bits;
    signed char depth;
    signed char flags;
};

typedef struct _interval_node interval_node[1];
typedef struct _interval_node *interval_nodep;

static
void
interval_node_init(interval_nodep inp, int start, int depth, int flags)
{
    inp->start = start;
    inp->flags = flags;
    inp->depth = depth;
    inp->bits = 0;
    inp->prefix = flags >= 0 ? flags : depth + 1;
    inp->score = -1;
    inp->next = NULL;
}

static
interval_nodep interval_node_clone(interval_nodep inp)
{
    interval_nodep inp2 = NULL;

    if(inp != NULL)
    {
	inp2 = malloc(sizeof(interval_node));
	if (inp2 == NULL)
	{
	    LOG(LOG_ERROR, ("out of memory error in file %s, line %d\n",
			    __FILE__, __LINE__));
	    exit(0);
	}
	/* copy contents */
	*inp2 = *inp;
	inp2->next = interval_node_clone(inp->next);
    }

    return inp2;
}

static
void interval_node_delete(interval_nodep inp)
{
    interval_nodep inp2;
    while (inp != NULL)
    {
        inp2 = inp;
        inp = inp->next;
        free(inp2);
    }
}

static
void interval_node_dump(int level, interval_nodep inp)
{
    int end;

    end = 0;
    while (inp != NULL)
    {
        end = inp->start + (1 << inp->bits);
        LOG(level, ("%X", inp->bits));
        inp = inp->next;
    }
    LOG(level, ("[eol@%d]\n", end));
}

float optimal_encode_int(int arg, void *priv, output_ctxp out)
{
    interval_nodep inp;
    int end;

    float val;

    inp = (interval_nodep) priv;
    val = 100000000.0;
    end = 0;
    while (inp != NULL)
    {
        end = inp->start + (1 << inp->bits);
        if (arg >= inp->start && arg < end)
        {
            break;
        }
        inp = inp->next;
    }
    if (inp != NULL)
    {
        val = (float) (inp->prefix + inp->bits);
    } else
    {
        val += (float) (arg - end);
    }
    LOG(LOG_DUMP, ("encoding %d to %0.1f bits\n", arg, val));

    if (out != NULL)
    {
        output_bits(out, inp->bits, arg - inp->start);
        if (inp->flags < 0)
        {
            LOG(LOG_DUMP, ("gamma prefix code = %d\n", inp->depth));
            output_gamma_code(out, inp->depth);
        } else
        {
            LOG(LOG_DUMP, ("flat prefix %d bits\n", inp->depth));
            output_bits(out, inp->prefix, inp->depth);
        }
    }

    return val;
}

float optimal_encode(const_matchp mp, encode_match_data emd)
{
    interval_nodep *offset;
    float bits;
    encode_match_privp data;

    data = emd->priv;
    offset = data->offset_f_priv;

    bits = 0.0;
    if (mp->offset == 0)
    {
        bits += 9.0f * mp->len;
        data->lit_num += mp->len;
        data->lit_bits += bits;
    } else
    {
        bits += 1.0;
        switch (mp->len)
        {
        case 0:
            LOG(LOG_ERROR, ("bad len\n"));
            exit(1);
            break;
        case 1:
            bits += data->offset_f(mp->offset, offset[0], emd->out);
            break;
        case 2:
            bits += data->offset_f(mp->offset, offset[1], emd->out);
            break;
        default:
            bits += data->offset_f(mp->offset, offset[7], emd->out);
            break;
        }
        bits += data->len_f(mp->len, data->len_f_priv, emd->out);
        if (bits > (9.0 * mp->len))
        {
            /* lets make literals out of it */
            data->lit_num += 1;
            data->lit_bits += bits;
        } else
        {
            if (mp->offset == 1)
            {
                data->rle_num += 1;
                data->rle_bits += bits;
            } else
            {
                data->seq_num += 1;
                data->seq_bits += bits;
            }
        }
    }
    return bits;
}

struct _optimize_arg {
    radix_root cache;
    int *stats;
    int *stats2;
    int max_depth;
    int flags;
    struct chunkpool in_pool[1];
};

#define CACHE_KEY(START, DEPTH, MAXDEPTH) ((int)((START)*(MAXDEPTH)|DEPTH))

typedef struct _optimize_arg optimize_arg[1];
typedef struct _optimize_arg optimize_argp;

static interval_nodep
optimize1(optimize_arg arg, int start, int depth, int init)
{
    interval_node inp;
    interval_nodep best_inp;
    int key;
    int end, i;
    int start_count, end_count;

    LOG(LOG_DUMP, ("IN start %d, depth %d\n", start, depth));

    do
    {
        best_inp = NULL;
        if (arg->stats[start] == 0)
        {
            break;
        }
        key = CACHE_KEY(start, depth, arg->max_depth);
        best_inp = radix_node_get(arg->cache, key);
        if (best_inp != NULL)
        {
            break;
        }

        interval_node_init(inp, start, depth, arg->flags);

        for (i = 0; i < 16; ++i)
        {
            inp->next = NULL;
            inp->bits = i;
            end = start + (1 << i);

            start_count = end_count = 0;
            if (start < 65536)
            {
                start_count = arg->stats[start];
                if (end < 65536)
                {
                    end_count = arg->stats[end];
                }
            }

            inp->score = (start_count - end_count) *
                (inp->prefix + inp->bits);

            /* one index below */
            LOG(LOG_DUMP, ("interval score: [%d�%d[%d\n",
                           start, i, inp->score));
            if (end_count > 0)
            {
                int penalty;
                /* we're not done, now choose between using
                 * more bits, go deeper or skip the rest */
                if (depth + 1 < arg->max_depth)
                {
                    /* we can go deeper, let's try that */
                    inp->next = optimize1(arg, end, depth + 1, i);
                }
                /* get the penalty for skipping */
                penalty = 100000000;
                if (arg->stats2 != NULL)
                {
                    penalty = arg->stats2[end];
                }
                if (inp->next != NULL && inp->next->score < penalty)
                {
                    penalty = inp->next->score;
                }
                inp->score += penalty;
            }
            if (best_inp == NULL || inp->score < best_inp->score)
            {
                /* it's the new best in town, use it */
                if (best_inp == NULL)
                {
                    /* allocate if null */
                    best_inp = chunkpool_malloc(arg->in_pool);
                }
                *best_inp = *inp;
            }
        }
        if (best_inp != NULL)
        {
            radix_node_set(arg->cache, key, best_inp);
        }
    }
    while (0);

    if(IS_LOGGABLE(LOG_DUMP))
    {
        LOG(LOG_DUMP, ("OUT depth %d: ", depth));
        interval_node_dump(LOG_DUMP, best_inp);
    }
    return best_inp;
}

static interval_nodep
optimize(int stats[65536], int stats2[65536], int max_depth, int flags)
{
    optimize_arg arg;

    interval_nodep inp;

    arg->stats = stats;
    arg->stats2 = stats2;

    arg->max_depth = max_depth;
    arg->flags = flags;

    chunkpool_init(arg->in_pool, sizeof(interval_node));

    radix_tree_init(arg->cache);

    inp = optimize1(arg, 1, 0, 0);

    /* use normal malloc for the winner */
    inp = interval_node_clone(inp);

    /* cleanup */
    radix_tree_free(arg->cache, NULL, NULL);
    chunkpool_free(arg->in_pool);

    return inp;
}

static const char *export_helper(interval_nodep np, int depth)
{
    static char buf[20];
    char *p = buf;
    while(np != NULL)
    {
        p += sprintf(p, "%X", np->bits);
        np = np->next;
        --depth;
    }
    while(depth-- > 0)
    {
        p += sprintf(p, "0");
    }
    return buf;
}

const char *optimal_encoding_export(encode_match_data emd)
{
    interval_nodep *offsets;
    static char buf[100];
    char *p = buf;
    encode_match_privp data;

    data = emd->priv;
    offsets = (interval_nodep*)data->offset_f_priv;
    p += sprintf(p, "%s", export_helper((interval_nodep)data->len_f_priv, 16));
    p += sprintf(p, ",%s", export_helper(offsets[0], 4));
    p += sprintf(p, ",%s", export_helper(offsets[1], 16));
    p += sprintf(p, ",%s", export_helper(offsets[7], 16));
    return buf;
}

static void import_helper(interval_nodep *npp,
                          const char **encodingp,
                          int flags)
{
    int c;
    int start = 1;
    int depth = 0;
    const char *encoding;

    encoding = *encodingp;
    while((c = *(encoding++)) != '\0')
    {
        char buf[2] = {0, 0};
        char *dummy;
        int bits;
        interval_nodep np;

        if(c == ',')
        {
            break;
        }

        buf[0] = c;
        bits = strtol(buf, &dummy, 16);

        LOG(LOG_DUMP, ("got bits %d\n", bits));

        np = malloc(sizeof(interval_node));
        interval_node_init(np, start, depth, flags);
        np->bits = bits;

        ++depth;
        start += 1 << bits;

        *npp = np;
        npp = &(np->next);
    }
    *encodingp = encoding;
}

void optimal_encoding_import(encode_match_data emd,
                             const char *encoding)
{
    encode_match_privp data;
    interval_nodep *npp, *offsets;

    LOG(LOG_DEBUG, ("importing encoding: %s\n", encoding));

    optimal_free(emd);
    optimal_init(emd);

    data = emd->priv;
    offsets = (interval_nodep*)data->offset_f_priv;

    /* lengths */
    npp = (void*)&data->len_f_priv;
    import_helper(npp, &encoding, -1);

    /* offsets, len = 1 */
    npp = &offsets[0];
    import_helper(npp, &encoding, 2);

    /* offsets, len = 2 */
    npp = &offsets[1];
    import_helper(npp, &encoding, 4);

    /* offsets, len >= 3 */
    npp = &offsets[7];
    import_helper(npp, &encoding, 4);

    LOG(LOG_DEBUG, ("imported encoding: "));
    optimal_dump(LOG_DEBUG, emd);
}

void optimal_init(encode_match_data emd)        /* IN/OUT */
{
    encode_match_privp data;
    interval_nodep *inpp;

    emd->priv = malloc(sizeof(encode_match_priv));
    data = emd->priv;

    memset(data, 0, sizeof(encode_match_priv));

    data->offset_f = optimal_encode_int;
    data->len_f = optimal_encode_int;
    inpp = malloc(sizeof(interval_nodep[8]));
    inpp[0] = NULL;
    inpp[1] = NULL;
    inpp[2] = NULL;
    inpp[3] = NULL;
    inpp[4] = NULL;
    inpp[5] = NULL;
    inpp[6] = NULL;
    inpp[7] = NULL;
    data->offset_f_priv = inpp;
    data->len_f_priv = NULL;
}

void optimal_free(encode_match_data emd)        /* IN */
{
    encode_match_privp data;
    interval_nodep *inpp;
    interval_nodep inp;

    data = emd->priv;

    inpp = data->offset_f_priv;
    if (inpp != NULL)
    {
        interval_node_delete(inpp[0]);
        interval_node_delete(inpp[1]);
        interval_node_delete(inpp[2]);
        interval_node_delete(inpp[3]);
        interval_node_delete(inpp[4]);
        interval_node_delete(inpp[5]);
        interval_node_delete(inpp[6]);
        interval_node_delete(inpp[7]);
    }
    free(inpp);

    inp = data->len_f_priv;
    interval_node_delete(inp);

    data->offset_f_priv = NULL;
    data->len_f_priv = NULL;
}

void freq_stats_dump(int level, int arr[65536])
{
    int i;
    for (i = 0; i < 32; ++i)
    {
        LOG(level, ("%d, ", arr[i] - arr[i + 1]));
    }
    LOG(level, ("\n"));
}

void freq_stats_dump_raw(int level, int arr[65536])
{
    int i;
    for (i = 0; i < 32; ++i)
    {
        LOG(level, ("%d, ", arr[i]));
    }
    LOG(level, ("\n"));
}

void optimal_optimize(encode_match_data emd,    /* IN/OUT */
                      matchp_enum_get_next_f * f,       /* IN */
                      void *matchp_enum)        /* IN */
{
    encode_match_privp data;
    const_matchp mp;
    interval_nodep *offset;
    static int offset_arr[8][65536];
    static int offset_parr[8][65536];
    static int len_arr[65536];
    int treshold;

    int i, j;
    void *priv1;

    data = emd->priv;

    memset(offset_arr, 0, sizeof(offset_arr));
    memset(offset_parr, 0, sizeof(offset_parr));
    memset(len_arr, 0, sizeof(len_arr));

    offset = data->offset_f_priv;

    /* first the lens */
    priv1 = matchp_enum;
#if 0
    while ((mp = f(priv1)) != NULL)
    {
        LOG(LOG_DEBUG, ("%p len %d offset %d\n", mp, mp->len, mp->offset));
    }
    if(mp->len < 0)
    {
        LOG(LOG_ERROR, ("the horror, negative len!\n"));
    }
#endif
    while ((mp = f(priv1)) != NULL && mp->len > 0)
    {
        if (mp->offset > 0)
        {
            len_arr[mp->len] += 1;
            if(len_arr[mp->len] < 0)
            {
                LOG(LOG_ERROR, ("len counter wrapped!\n"));
            }
        }
    }

    for (i = 65534; i >= 0; --i)
    {
        len_arr[i] += len_arr[i + 1];
        if(len_arr[i] < 0)
        {
            LOG(LOG_ERROR, ("len counter wrapped!\n"));
        }
    }

    data->len_f_priv = optimize(len_arr, NULL, 16, -1);

    /* then the offsets */
    priv1 = matchp_enum;
    while ((mp = f(priv1)) != NULL && mp->len > 0)
    {
        if (mp->offset > 0)
        {
            treshold = mp->len * 9;
            treshold -= 1 + (int) optimal_encode_int(mp->len,
                                                     data->len_f_priv,
                                                     NULL);
            switch (mp->len)
            {
            case 0:
                LOG(LOG_ERROR, ("bad len\n"));
                exit(0);
                break;
            case 1:
                offset_parr[0][mp->offset] += treshold;
                offset_arr[0][mp->offset] += 1;
                if(offset_arr[0][mp->offset] < 0)
                {
                    LOG(LOG_ERROR, ("offset0 counter wrapped!\n"));
                }
                break;
            case 2:
                offset_parr[1][mp->offset] += treshold;
                offset_arr[1][mp->offset] += 1;
                if(offset_arr[1][mp->offset] < 0)
                {
                    LOG(LOG_ERROR, ("offset1 counter wrapped!\n"));
                }
                break;
            default:
                offset_parr[7][mp->offset] += treshold;
                offset_arr[7][mp->offset] += 1;
                if(offset_arr[7][mp->offset] < 0)
                {
                    LOG(LOG_ERROR, ("offset7 counter wrapped!\n"));
                }
                break;
            }
        }
    }

    for (i = 65534; i >= 0; --i)
    {
        for (j = 0; j < 8; ++j)
        {
            offset_arr[j][i] += offset_arr[j][i + 1];
            offset_parr[j][i] += offset_parr[j][i + 1];
        }
    }

    offset[0] = optimize(offset_arr[0], offset_parr[0], 1 << 2, 2);
    offset[1] = optimize(offset_arr[1], offset_parr[1], 1 << 4, 4);
    offset[2] = optimize(offset_arr[2], offset_parr[2], 1 << 4, 4);
    offset[3] = optimize(offset_arr[3], offset_parr[3], 1 << 4, 4);
    offset[4] = optimize(offset_arr[4], offset_parr[4], 1 << 4, 4);
    offset[5] = optimize(offset_arr[5], offset_parr[5], 1 << 4, 4);
    offset[6] = optimize(offset_arr[6], offset_parr[6], 1 << 4, 4);
    offset[7] = optimize(offset_arr[7], offset_parr[7], 1 << 4, 4);

    if(IS_LOGGABLE(LOG_DEBUG))
    {
        optimal_dump(LOG_DEBUG, emd);
    }
}

void optimal_dump(int level, encode_match_data emd)
{
    encode_match_privp data;
    interval_nodep *offset;
    interval_nodep len;

    data = emd->priv;

    offset = data->offset_f_priv;
    len = data->len_f_priv;

    LOG(level, ("lens:             "));
    interval_node_dump(level, len);

    LOG(level, ("offsets (len =1): "));
    interval_node_dump(level, offset[0]);

    LOG(level, ("offsets (len =2): "));
    interval_node_dump(level, offset[1]);

    LOG(level, ("offsets (len =8): "));
    interval_node_dump(level, offset[7]);
}

static
void interval_out(output_ctx out, interval_nodep inp1, int size)
{
    unsigned char buffer[256];
    unsigned char count;
    interval_nodep inp;

    count = 0;

    memset(buffer, 0, sizeof(buffer));
    inp = inp1;
    while (inp != NULL)
    {
        ++count;
        LOG(LOG_DUMP, ("bits %d, lo %d, hi %d\n",
                       inp->bits, inp->start & 0xFF, inp->start >> 8));
        buffer[sizeof(buffer) - count] = inp->bits;
        inp = inp->next;
    }

    while (size > 0)
    {
        int b;
        b = buffer[sizeof(buffer) - size];
        LOG(LOG_DUMP, ("outputting nibble %d\n", b));
        output_bits(out, 4, b);
        size--;
    }
}

void optimal_out(output_ctx out,        /* IN/OUT */
                 encode_match_data emd) /* IN */
{
    encode_match_privp data;
    interval_nodep *offset;
    interval_nodep len;

    data = emd->priv;

    offset = data->offset_f_priv;
    len = data->len_f_priv;

    interval_out(out, offset[0], 4);
    interval_out(out, offset[1], 16);
    interval_out(out, offset[7], 16);
    interval_out(out, len, 16);
}
