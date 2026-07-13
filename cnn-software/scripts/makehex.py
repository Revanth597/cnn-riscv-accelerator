#!/usr/bin/env python3
import sys

if len(sys.argv) != 2:
    print("Usage: python makehex.py <binary_file>", file=sys.stderr)
    sys.exit(1)

binfile = sys.argv[1]

with open(binfile, "rb") as f:
    bindata = f.read()


if len(bindata) % 4 != 0:
    print("Error: binary is not aligned to 4-byte words.", file=sys.stderr)
    print("length of data", len(bindata), file=sys.stderr)
    sys.exit(1)

nwords = len(bindata) // 4

for i in range(nwords):
    w = bindata[4 * i : 4 * i + 4]
    print("%02x%02x%02x%02x" % (w[3], w[2], w[1], w[0]))
