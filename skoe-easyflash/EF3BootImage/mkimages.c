
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>
#include <strings.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static unsigned char buff[1024 * 1024];
static FILE*    fp;
static size_t   crt_size;

#define MAX_BANK  0x7f
#define BANK_SIZE 0x2000

#define BANKING_L  0
#define BANKING_H  1
#define BANKING_LH 2


/******************************************************************************/
/**
 * Read a binary image and write it to the CRT file.
 * Return 1 on success, 0 on error.
 */
static int write_bin(char* filename, long bank, long offset, int banking)
{
    FILE *fp;
    struct stat st;
    size_t abs_offset, rest, read_size;

    abs_offset = 2 * BANK_SIZE * bank + offset;
    if (banking == BANKING_H)
        abs_offset += BANK_SIZE;

    if (stat(filename, &st))
    {
        fprintf(stderr, "Cannot stat %s: %s\n", filename, strerror(errno));
        return 0;
    }

    // todo: this depends from the banking scheme:
    if (st.st_size > sizeof(buff) - abs_offset)
    {
        fprintf(stderr, "File %s is too large!\n", filename);
        return 0;
    }

    fp = fopen(filename, "rb");
    if (fp == NULL)
    {
        fprintf(stderr, "Cannot open %s: %s\n", filename, strerror(errno));
        return 0;
    }
    if (banking == BANKING_LH)
    {
        if (fread(buff + abs_offset, 1, st.st_size, fp) < st.st_size)
        {
            fprintf(stderr, "Cannot read %s: %s\n", filename, strerror(errno));
            return 0;
        }
    }
    else
    {
        rest = st.st_size;
        while (rest > 0)
        {
            read_size = fread(buff + abs_offset, 1, BANK_SIZE, fp);
            if (read_size < 1)
            {
                fprintf(stderr, "Cannot read %s: %s\n", filename, strerror(errno));
                return 0;
            }
            rest -= read_size;
            abs_offset += 2 * BANK_SIZE;
        }
    }

    fclose(fp);

    return 1;
}


/******************************************************************************/
/**
 * Parse banking scheme, one of "l", "h", "lh".
 * Return BANKING_* on success, -1 on error.
 */
static int parse_banking(const char* str)
{
    if (strcasecmp(str, "l") == 0)
        return BANKING_L;
    else if (strcasecmp(str, "h") == 0)
        return BANKING_H;
    else if (strcasecmp(str, "lh") == 0)
        return BANKING_LH;

    return -1;
}


/******************************************************************************/
int main(int argc, char *argv[])
{
    int i, banking;
    long bank, offset;
    char *filename;

    memset(buff, 0xff, sizeof(buff));

    if (argc < 5 || ((argc - 2) % 4) != 0)
    {
        fprintf(stderr,
                "Usage: %s binfile bankno offset lh [binfile bankno offset lh...] crtfile\n", argv[0]);
        return 1;
    }

    filename = argv[argc-1];
    fp = fopen(filename, "wb");

    if (fp == NULL)
    {
        fprintf(stderr, "Cannot open %s: %s\n", argv[argc-1], strerror(errno));
        return 1;
    }

    for (i = 1; i < argc-1; i += 4)
    {
        char *endptr;

        bank = strtol(argv[i + 1], &endptr, 0);
        if (*endptr != 0 || bank < 0 || bank > MAX_BANK)
        {
            fprintf(stderr, "Invalid bank: %s\n", argv[i+1]);
            goto error;
        }

        offset = strtol(argv[i + 2], &endptr, 0);
        if (*endptr != 0 || offset < 0 || offset >= BANK_SIZE)
        {
            fprintf(stderr, "Invalid offset: %s\n", argv[i+2]);
            goto error;
        }

        banking = parse_banking(argv[i + 3]);
        if (banking == -1)
        {
            fprintf(stderr, "Invalid banking scheme: %s\n", argv[i + 3]);
            goto error;
        }

        if (!write_bin(argv[i], bank, offset, banking))
            goto error;
    }

    if (fwrite(buff, sizeof(buff), 1, fp) != 1)
    {
        fprintf(stderr, "Failed to write binary image to %s: %s\n",
                filename, strerror(errno));
        goto error;
    }
    fclose(fp);
    return 0;

error:
    fclose(fp);
    remove(argv[argc-1]);
    return 1;
}
