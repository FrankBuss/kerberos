/*
 * This file has been modified by Thomas Giesel:
 * - return value instead of calling exit() directly
 *
 */
/*
 * Copyright (c) 2005 Magnus Lind.
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

#include "membuf_io.h"
#include "log.h"
#include <stdio.h>
#include <stdlib.h>

/* return != 0 for error */

int read_file(const char *name, struct membuf *buf)
{
    char block[1024];
    FILE *in;
    int len;

    in = fopen(name, "rb");
    if(in == NULL)
    {
        LOG(LOG_ERROR, ("Can't open file \"%s\" for input.\n", name));
        return 1;
    }
    do
    {
        len = fread(block, 1, 1024, in);
        membuf_append(buf, block, len);
    }
    while(len == 1024);
    LOG(LOG_DEBUG, ("read %d bytes from file\n", len));
    fclose(in);
    return 0;
}

/* return != 0 for error */

int write_file(const char *name, struct membuf *buf)
{
    FILE *out;
    out = fopen(name, "wb");
    if(out == NULL)
    {
        LOG(LOG_ERROR, ("Can't open file \"%s\" for output.\n", name));
        return 1;
    }
    fwrite(membuf_get(buf), 1, membuf_memlen(buf), out);
    fclose(out);
    return 0;
}
