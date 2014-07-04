/*
 * Copyright (c) 2003 - 2005 Magnus Lind.
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

#include "chunkpool.h"
#include "log.h"
#include <stdlib.h>
#include <string.h>

void
chunkpool_init(struct chunkpool *ctx, int size)
{
    ctx->chunk_size = size;
    ctx->chunk = -1;
    ctx->chunk_max = (0x1fffff / size) * size;
    ctx->chunk_pos = ctx->chunk_max;
}

void
chunkpool_free2(struct chunkpool *ctx, cb_free *f)
{
    while(ctx->chunk >= 0)
    {
        if(f != NULL)
        {
            do
            {
                ctx->chunk_pos -= ctx->chunk_size;
                f((char*)ctx->chunks[ctx->chunk] + ctx->chunk_pos);
            }
            while(ctx->chunk_pos > 0);
            ctx->chunk_pos = ctx->chunk_max;
        }
	free(ctx->chunks[ctx->chunk]);
	ctx->chunk -= 1;
    }
    ctx->chunk_size = -1;
    ctx->chunk_max = -1;
    ctx->chunk_pos = -1;
}

void
chunkpool_free(struct chunkpool *ctx)
{
    chunkpool_free2(ctx, NULL);
}

void *
chunkpool_malloc(struct chunkpool *ctx)
{
    void *p;
    if(ctx->chunk_pos == ctx->chunk_max)
    {
	void *m;
	if(ctx->chunk == CHUNKPOOL_CHUNKS_MAX - 1)
	{
	    LOG(LOG_ERROR, ("out of chunks in file %s, line %d\n",
			    __FILE__, __LINE__));
	    LOG(LOG_BRIEF, ("chunk_size %d\n", ctx->chunk_size));
	    LOG(LOG_BRIEF, ("chunk_max %d\n", ctx->chunk_max));
	    LOG(LOG_BRIEF, ("chunk %d\n", ctx->chunk));
	    exit(-1);
	}
	m = malloc(ctx->chunk_max);
        LOG(LOG_DEBUG, ("allocating new chunk %p\n", m));
	if (m == NULL)
	{
	    LOG(LOG_ERROR, ("out of memory error in file %s, line %d\n",
			    __FILE__, __LINE__));
	    exit(-1);
	}
	ctx->chunk += 1;
	ctx->chunks[ctx->chunk] = m;
	ctx->chunk_pos = 0;
    }
    p = (char*)ctx->chunks[ctx->chunk] + ctx->chunk_pos;
    ctx->chunk_pos += ctx->chunk_size;
    return p;
}

void *
chunkpool_calloc(struct chunkpool *ctx)
{
    void *p = chunkpool_malloc(ctx);
    memset(p, 0, ctx->chunk_size);
    return p;
}
