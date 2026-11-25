"""Draw an original pixel-art cat as an animated GIF, no dependencies."""
import struct, sys

PAL = {'.': None, 'k': (108, 112, 134), 'o': (245, 166, 80), 'd': (214, 125, 50),
       'w': (250, 244, 235), 'p': (242, 140, 170), 'g': (120, 220, 140)}
KEYS = ['.', 'k', 'o', 'd', 'w', 'p', 'g']

BASE = [
    ".k........k.",
    "kok......kok",
    "kopk....kpok",
    "koookkkkoook",
    "kooooooooook",
    "EYES",
    "kwoooppooowk",
    "kwwwkwwkwwwk",
    ".kwwwwwwwwk.",
    "kooowwwwoook",
    "koowwwwwwook",
    "koowwwwwwook",
    "koowwwwwwook",
    "kooowwwwoook",
    "kwwkooookwwk",
    "kkkkkkkkkkkk",
]
OPEN, SHUT = "koggooooggok", "kokkookkookok"[:12]
TAILS = [
    [(12, 14), (13, 13), (14, 12), (14, 11), (14, 10), (13, 9)],
    [(12, 14), (13, 14), (14, 13), (15, 12), (15, 11), (16, 10)],
    [(12, 14), (13, 14), (14, 14), (15, 13), (16, 12), (17, 11)],
]
W, H, TOP, SCALE = 19, 18, 2, 6

def frame(tail, blink):
    g = [['.'] * W for _ in range(H)]
    for y, row in enumerate(BASE):
        row = (SHUT if blink else OPEN) if row == "EYES" else row
        for x, c in enumerate(row):
            g[y + TOP][x] = c
    for x, y in TAILS[tail]:
        g[y + TOP][x] = 'd'
        if y + TOP + 1 < H and g[y + TOP + 1][x] == '.':
            g[y + TOP + 1][x] = 'k'          # little shadow under the tail
    px = []
    for row in g:
        line = [KEYS.index(c) for c in row for _ in range(SCALE)]
        px += line * SCALE
    return px

def lzw_literal(px, mcs=7):
    clear, eoi = 1 << mcs, (1 << mcs) + 1
    codes = []
    for i in range(0, len(px), 120):
        codes.append(clear); codes += px[i:i + 120]
    codes.append(eoi)
    out, acc, n = bytearray(), 0, 0
    for c in codes:
        acc |= c << n; n += mcs + 1
        while n >= 8:
            out.append(acc & 255); acc >>= 8; n -= 8
    if n: out.append(acc & 255)
    return bytes([mcs]) + b''.join(bytes([len(out[i:i+255])]) + out[i:i+255]
                                    for i in range(0, len(out), 255)) + b'\0'

def write(path, frames):
    w, h = W * SCALE, H * SCALE
    pal = bytearray()
    for k in KEYS: pal += bytes(PAL[k] or (0, 0, 0))
    pal += bytes(3 * (128 - len(KEYS)))
    b = bytearray(b'GIF89a' + struct.pack('<HHBBB', w, h, 0xF6, 0, 0) + pal)
    b += b'\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00'   # loop forever
    for px, delay in frames:
        b += b'\x21\xf9\x04' + struct.pack('<BHB', 0x09, delay, 0) + b'\0'
        b += b'\x2c' + struct.pack('<HHHHB', 0, 0, w, h, 0) + lzw_literal(px)
    b += b'\x3b'
    open(path, 'wb').write(b)

# tail swish back and forth, with a blink now and then
seq = [(0,0),(1,0),(2,0),(1,0),(0,0),(1,0),(2,0),(1,0),(0,1),(0,0),(1,0),(2,0),(2,1),(1,0)]
write(sys.argv[1], [(frame(t, bl), 18) for t, bl in seq])
