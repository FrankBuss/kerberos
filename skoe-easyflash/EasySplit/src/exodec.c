/*
 * Copyright (c) 2002 - 2005 Magnus Lind.
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must not
 *   claim that you wrote the original software. If you use this software in a
 *   product, an acknowledgment in the product documentation would be
 *   appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must not
 *   be misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any source distribution.
 *
 */
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "exodec.h"
#include "log.h"

char *get(struct membuf *buf)
{
    return membuf_get(buf);
}

int
get_byte(struct dec_ctx *ctx)
{
    int c;
    if(ctx->inpos == ctx->inend)
    {
        LOG(LOG_ERROR, ("unexpected end of input data\n"));
        exit(-1);
    }
    c = ctx->inbuf[ctx->inpos++];

    return c;
}

int
get_bits(struct dec_ctx *ctx, int count)
{
    int val;

    val = 0;

    /*printf("get_bits: count = %d", count);*/
    while(count-- > 0) {
        if((ctx->bitbuf & 0x1FF) == 1) {
            ctx->bitbuf = get_byte(ctx) | 0x100;
        }
        val <<= 1;
        val |= ctx->bitbuf & 0x1;
        ctx->bitbuf >>= 1;
        /*printf("bit read %d\n", val &1);*/
        ctx->bits_read++;
    }
    /*printf(" val = %d\n", val);*/
    return val;
}

int
get_gamma_code(struct dec_ctx *ctx)
{
    int gamma_code;
    /* get bitnum index */
    gamma_code = 0;
    while(get_bits(ctx, 1) == 0)
    {
        ++gamma_code;
    }
    return gamma_code;
}

int
get_cooked_code_phase2(struct dec_ctx *ctx, int index)
{
    int base;
    struct dec_table *tp;
    tp = ctx->t;

    base = tp->table_lo[index] | (tp->table_hi[index] << 8);
    return base + get_bits(ctx, tp->table_bi[index]);
}

static
void
table_init(struct dec_ctx *ctx, struct dec_table *tp) /* IN/OUT */
{
    int i;
    unsigned int a = 0;
    unsigned int b = 0;

    tp->table_bit[0] = 2;
    tp->table_bit[1] = 4;
    tp->table_bit[2] = 4;

    tp->table_off[0] = 48;
    tp->table_off[1] = 32;
    tp->table_off[2] = 16;

    for(i = 0; i < 52; ++i)
    {
        if(i & 0xF)
        {
            a += 1 << b;
        } else
        {
            a = 1;
        }

        tp->table_lo[i] = a & 0xFF;
        tp->table_hi[i] = a >> 8;

        b = get_bits(ctx, 4);

        tp->table_bi[i] = b;

    }
}

char *
table_dump(struct dec_table *tp)
{
    int i, j;
    static char buf[100];
    char *p = buf;

    for(i = 0; i < 16; ++i)
    {
        p += sprintf(p, "%X", tp->table_bi[i]);
    }
    for(j = 0; j < 3; ++j)
    {
        int start;
        int end;
        p += sprintf(p, ",");
        start = tp->table_off[j];
        end = start + (1 << tp->table_bit[j]);
        for(i = start; i < end; ++i)
        {
            p += sprintf(p, "%X", tp->table_bi[i]);
        }
    }
    return buf;
}

char *
dec_ctx_init(struct dec_ctx *ctx, struct membuf *inbuf, struct membuf *outbuf)
{
    char *encoding;
    ctx->bits_read = 0;

    ctx->inbuf = membuf_get(inbuf);
    ctx->inend = membuf_memlen(inbuf);
    ctx->inpos = 0;

    ctx->outbuf = outbuf;

    /* init bitbuf */
    ctx->bitbuf = get_byte(ctx);

    /* init tables */
    table_init(ctx, ctx->t);
    encoding = table_dump(ctx->t);
    return encoding;
}

void dec_ctx_free(struct dec_ctx *ctx)
{
}

void dec_ctx_decrunch(struct dec_ctx ctx[1])
{
    int bits;
    int val;
    int i;
    int len;
    int offset;
    int src = 0;

    for(;;)
    {
        int literal = 0;
        bits = ctx->bits_read;
        if(get_bits(ctx, 1))
        {
            /* literal */
            len = 1;

            LOG(LOG_DEBUG, ("[%d] literal\n", membuf_memlen(ctx->outbuf)));

            literal = 1;
            goto literal;
        }

        val = get_gamma_code(ctx);
        if(val == 16)
        {
            /* done */
            break;
        }
        if(val == 17)
        {
            len = get_bits(ctx, 16);
            literal = 1;

            LOG(LOG_DEBUG, ("[%d] literal copy len %d\n",
                            membuf_memlen(ctx->outbuf), len));

            goto literal;
        }

        len = get_cooked_code_phase2(ctx, val);

        i = (len > 3 ? 3 : len) - 1;

        val = ctx->t->table_off[i] + get_bits(ctx, ctx->t->table_bit[i]);
        offset = get_cooked_code_phase2(ctx, val);

        LOG(LOG_DEBUG, ("[%d] sequence offset = %d, len = %d\n",
                        membuf_memlen(ctx->outbuf), offset, len));

        src = membuf_memlen(ctx->outbuf) - offset;

    literal:
        do {
            if(literal)
            {
                val = get_byte(ctx);
            }
            else
            {
                val = get(ctx->outbuf)[src++];
            }
            membuf_append_char(ctx->outbuf, val);
        } while (--len > 0);

        LOG(LOG_DEBUG, ("bits read for this iteration %d.\n",
                        ctx->bits_read - bits));
    }
}
