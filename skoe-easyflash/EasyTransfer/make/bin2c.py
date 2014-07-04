#!/usr/bin/env python
import sys


if __name__ == '__main__':
    if len(sys.argv) == 4:
        if sys.argv[1] == '-':
            instream = sys.stdin
        else:
            instream = file(sys.argv[1],'rb')
        if sys.argv[2] == '-':
            outstream = sys.stdout
        else:
            outstream = file(sys.argv[2], 'wt')
        varname = sys.argv[3]
    else:
        print "Usage: bin2c infile outfile varname"
        sys.exit(0)

    outstream.write("\n\nconst unsigned char %s[] = {\n    " % varname)
    written = 0
    while True:
        byte = instream.read(1)
        if len(byte) != 1:
            break
        outstream.write( "0x%.2x, " % ord(byte) )
        written += 1
        if written % 16 == 0:
            outstream.write( "\n    " )
    outstream.write("\n};\n")
    outstream.write("\nint %s_size = %i;\n\n" % (varname, written))

    sys.exit(0)
