/*
 * Copyright (c) 2002 - 2005 Magnus Lind.
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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "log.h"
#include "search.h"
#include "membuf.h"
#include "progress.h"

void search_node_free(search_nodep snp) /* IN */
{
    /* emty now since snp:s are stored in an array */
}

search_nodep search_buffer(match_ctx ctx,       /* IN */
                           encode_match_f * f,  /* IN */
                           encode_match_data emd,       /* IN */
                           int use_literal_sequences)
{
    struct progress prog[1];
    static struct membuf backing[1] = { STATIC_MEMBUF_INIT };
    static search_node *snp_arr;
    const_matchp mp = NULL;
    search_nodep snp;
    search_nodep best_copy_snp;
    int best_copy_len;

    search_nodep best_rle_snp;

    int len = ctx->len + 1;

    progress_init(prog, "finding.cheapest.path.",len, 0);

    membuf_atleast(backing, len * sizeof(search_node));
    snp_arr = membuf_get(backing);
    memset(snp_arr, 0, len * sizeof(search_node));

    --len;
    snp = snp_arr[len];
    snp->index = len;
    snp->match->offset = 0;
    snp->match->len = 0;
    snp->total_offset = 0;
    snp->total_score = 0;
    snp->prev = NULL;

    best_copy_snp = snp;
    best_copy_len = 0.0;

    best_rle_snp = NULL;

    /* think twice about changing this code,
     * it works the way it is. The last time
     * I examined this code I was certain it was
     * broken and broke it myself, trying to fix it. */
    while (len > 0 && (mp = matches_get(ctx, len - 1)) != NULL)
    {
        float prev_score;
        float prev_offset_sum;

        if(use_literal_sequences)
        {
            /* check if we can do even better with copy */
            snp = snp_arr[len];
            if(best_copy_snp->total_score+best_copy_len * 8.0 -
               snp->total_score > 0.0 || best_copy_len > 65535)
            {
                /* found a better copy endpoint */
                LOG(LOG_DEBUG,
                    ("best copy start moved to index %d\n", snp->index));
                best_copy_snp = snp;
                best_copy_len = 0.0;
            } else
            {
                float copy_score = best_copy_len * 8.0 + (1.0 + 17.0 + 17.0);
                float total_copy_score = best_copy_snp->total_score +
                                         copy_score;

                LOG(LOG_DEBUG,
                    ("total score %0.1f, copy total score %0.1f\n",
                     snp->total_score, total_copy_score));

                if(snp->total_score > total_copy_score )
                {
                    match local_mp;
                    /* here it is good to just copy instead of crunch */

                    LOG(LOG_DEBUG,
                        ("copy index %d, len %d, total %0.1f, copy %0.1f\n",
                         snp->index, best_copy_len,
                         snp->total_score, total_copy_score));

                    local_mp->len = best_copy_len;
                    local_mp->offset = 0;
                    local_mp->next = NULL;
                    snp->total_score = total_copy_score;
                    snp->total_offset = best_copy_snp->total_offset;
                    snp->prev = best_copy_snp;
                    *snp->match = *local_mp;
                }
            }
            /* end of copy optimization */
        }

        /* check if we can do rle */
        snp = snp_arr[len];
        if(best_rle_snp == NULL ||
           snp->index + 65535 < best_rle_snp->index ||
           snp->index + ctx->rle_r[snp->index] < best_rle_snp->index)
        {
            /* best_rle_snp can't be reached by rle from snp, reset it*/
            if(ctx->rle[snp->index] > 0)
            {
                best_rle_snp = snp;
                LOG(LOG_DEBUG, ("resetting best_rle at index %d, len %d\n",
                                 snp->index, ctx->rle[snp->index]));
            }
            else
            {
                best_rle_snp = NULL;
            }
        }
        else if(ctx->rle[snp->index] > 0 &&
                snp->index + ctx->rle_r[snp->index] >= best_rle_snp->index)
        {
            float best_rle_score;
            float total_best_rle_score;
            float snp_rle_score;
            float total_snp_rle_score;
            match rle_mp;

            LOG(LOG_DEBUG, ("challenger len %d, index %d, "
                             "ruling len %d, index %d\n",
                             ctx->rle_r[snp->index], snp->index,
                             ctx->rle_r[best_rle_snp->index],
                             best_rle_snp->index));

            /* snp and best_rle_snp is the same rle area,
             * let's see which is best */
#undef NEW_STYLE
#ifdef NEW_STYLE
            rle_mp->len = best_rle_snp->index - snp->index;
#else
            rle_mp->len = ctx->rle[best_rle_snp->index];
#endif
            rle_mp->offset = 1;
            best_rle_score = f(rle_mp, emd);
            total_best_rle_score = best_rle_snp->total_score +
                best_rle_score;

#ifdef NEW_STYLE
            snp_rle_score = 0.0;
#else
            rle_mp->len = ctx->rle[snp->index];
            rle_mp->offset = 1;
            snp_rle_score = f(rle_mp, emd);
#endif
            total_snp_rle_score = snp->total_score + snp_rle_score;

            if(total_snp_rle_score <= total_best_rle_score)
            {
                /* yes, the snp is a better rle than best_rle_snp */
                LOG(LOG_DEBUG, ("prospect len %d, index %d, (%0.1f+%0.1f) "
                                 "ruling len %d, index %d (%0.1f+%0.1f)\n",
                                 ctx->rle[snp->index], snp->index,
                                 snp->total_score, snp_rle_score,
                                 ctx->rle[best_rle_snp->index],
                                 best_rle_snp->index,
                                 best_rle_snp->total_score, best_rle_score));
                best_rle_snp = snp;
                LOG(LOG_DEBUG, ("setting current best_rle: "
                                 "index %d, len %d\n",
                                 snp->index, rle_mp->len));
            }
        }
        if(best_rle_snp != NULL && best_rle_snp != snp)
        {
            float rle_score;
            float total_rle_score;
            /* check if rle is better */
            match local_mp;
            local_mp->len = best_rle_snp->index - snp->index;
            local_mp->offset = 1;

            rle_score = f(local_mp, emd);
            total_rle_score = best_rle_snp->total_score + rle_score;

            LOG(LOG_DEBUG, ("comparing index %d (%0.1f) with "
                             "rle index %d, len %d, total score %0.1f %0.1f\n",
                             snp->index, snp->total_score,
                             best_rle_snp->index, local_mp->len,
                             best_rle_snp->total_score, rle_score));

            if(snp->total_score > total_rle_score)
            {
                /*here it is good to do rle instead of crunch */
                LOG(LOG_DEBUG,
                    ("rle index %d, len %d, total %0.1f, rle %0.1f\n",
                     snp->index, local_mp->len,
                     snp->total_score, total_rle_score));

                snp->total_score = total_rle_score;
                snp->total_offset = best_rle_snp->total_offset + 1;
                snp->prev = best_rle_snp;

                *snp->match = *local_mp;
            }
        }
        /* end of rle optimization */

        LOG(LOG_DUMP,
            ("matches for index %d with total score %0.1f\n",
             len - 1, snp->total_score));

        prev_score = snp_arr[len]->total_score;
        prev_offset_sum = snp_arr[len]->total_offset;
        while (mp != NULL)
        {
            matchp next;
            int end_len;

            match tmp;

            next = mp->next;
            end_len = 1;
#if 0
            if(next != NULL)
            {
                end_len = next->len + (next->offset > 0);
            }
#endif
            *tmp = *mp;
#if 1
            tmp->next = NULL;
#endif
            for(tmp->len = mp->len; tmp->len >= end_len; --(tmp->len))
            {
                float score;
                float total_score;
                unsigned int total_offset;

                LOG(LOG_DUMP, ("mp[%d, %d], tmp[%d, %d]\n",
                               mp->offset, mp->len,
                               tmp->offset, tmp->len));

                score = f(tmp, emd);
                total_score = prev_score + score;
                total_offset = prev_offset_sum + tmp->offset;
                snp = snp_arr[len - tmp->len];

                LOG(LOG_DUMP,
                    ("[%05d] cmp [%05d, %05d score %.1f + %.1f] with %.1f",
                     len, tmp->offset, tmp->len,
                     prev_score, score, snp->total_score));

                if ((total_score < 100000000.0) &&
                    (snp->match->len == 0 ||
                     total_score < snp->total_score ||
                     (total_score == snp->total_score &&
#if 1
                      (tmp->offset == 0 ||
                       (snp->match->len == tmp->len &&
                        (total_offset <= snp->total_offset))))))
#endif
                {
                    LOG(LOG_DUMP, (", replaced"));
                    snp->index = len - tmp->len;

                    *snp->match = *tmp;
                    snp->total_offset = total_offset;
                    snp->total_score = total_score;
                    snp->prev = snp_arr[len];
                }
                LOG(LOG_DUMP, ("\n"));
            }
            LOG(LOG_DUMP, ("tmp->len %d, ctx->rle[%d] %d\n",
                           tmp->len, len - tmp->len,
                           ctx->rle[len - tmp->len]));

            mp = next;
        }

        /* slow way to get to the next node for cur */
        --len;
        ++best_copy_len;
        if(snp_arr[len]->match == NULL)
        {
            LOG(LOG_ERROR, ("Found unreachable node at len %d.\n", len));
        }

        progress_bump(prog, len);
    }
    if(len > 0 && mp == NULL)
    {
        LOG(LOG_ERROR, ("No matches at len %d.\n", len));
    }
    LOG(LOG_NORMAL, ("\n"));

    progress_free(prog);

    return snp_arr[0];
}

void matchp_snp_get_enum(const_search_nodep snp,        /* IN */
                         matchp_snp_enum snpe)  /* IN/OUT */
{
    snpe->startp = snp;
    snpe->currp = snp;
}

const_matchp matchp_snp_enum_get_next(void *matchp_snp_enum)
{
    matchp_snp_enump snpe;
    const_matchp val;

    snpe = matchp_snp_enum;

    val = NULL;
    while (snpe->currp != NULL && val == NULL)
    {
        val = snpe->currp->match;
        snpe->currp = snpe->currp->prev;
    }

    if (snpe->currp == NULL)
    {
        snpe->currp = snpe->startp;
    }
    return val;
}
