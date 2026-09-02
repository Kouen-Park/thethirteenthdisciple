import struct
import sys
import zlib

path = sys.argv[1]
with open(path, "rb") as handle:
    payload = handle.read()
assert payload[:8] == b"\x89PNG\r\n\x1a\n"
pos = 8
idat = b""
width = height = color_type = bit_depth = None
while pos < len(payload):
    length = struct.unpack(">I", payload[pos:pos + 4])[0]
    chunk = payload[pos + 4:pos + 8]
    data = payload[pos + 8:pos + 8 + length]
    pos += length + 12
    if chunk == b"IHDR":
        width, height, bit_depth, color_type = struct.unpack(">IIBB", data[:10])
    elif chunk == b"IDAT":
        idat += data
    elif chunk == b"IEND":
        break
print(f"path={path}")
print(f"size={width}x{height}, bit_depth={bit_depth}, color_type={color_type}")
print("color_type_6=RGBA, color_type_4=grayscale+alpha, other=likely no alpha")
if color_type not in (4, 6):
    print("alpha_channel=NONE")
    raise SystemExit(0)
raw = zlib.decompress(idat)
channels = 4 if color_type == 6 else 2
bytes_per_pixel = channels * bit_depth // 8
stride = width * bytes_per_pixel
rows = []
previous = bytearray(stride)
pos = 0
for _ in range(height):
    filter_type = raw[pos]
    pos += 1
    row = bytearray(raw[pos:pos + stride])
    pos += stride
    for i in range(stride):
        left = row[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
        up = previous[i]
        upper_left = previous[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
        if filter_type == 1:
            row[i] = (row[i] + left) & 255
        elif filter_type == 2:
            row[i] = (row[i] + up) & 255
        elif filter_type == 3:
            row[i] = (row[i] + ((left + up) // 2)) & 255
        elif filter_type == 4:
            p = left + up - upper_left
            pa, pb, pc = abs(p - left), abs(p - up), abs(p - upper_left)
            predictor = left if pa <= pb and pa <= pc else (up if pb <= pc else upper_left)
            row[i] = (row[i] + predictor) & 255
        elif filter_type != 0:
            raise ValueError(f"unsupported filter {filter_type}")
    rows.append(row)
    previous = row
alpha_offset = 3 if color_type == 6 else 1
alphas = [row[i] for row in rows for i in range(alpha_offset, len(row), bytes_per_pixel)]
print(f"transparent={sum(value == 0 for value in alphas)}")
print(f"opaque={sum(value == 255 for value in alphas)}")
print(f"partial={sum(0 < value < 255 for value in alphas)}")
