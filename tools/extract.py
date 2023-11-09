#!/usr/bin/env python3
import struct
from PIL import Image

def decompress(data, offset, word = True):
    if word:
        b = struct.unpack_from(">HHHH", data, offset)
    else:
        b = struct.unpack_from(">BBBB", data, offset)
    offset += 8 if word else 4
    assetSize = struct.unpack(">I", bytearray(b))[0]

    outBuffer = []
    tempBuffer = [0x20] * 0x1000
    tempIndex = 0xFEE
    while assetSize > 0:
        if word:
            offset += 1
        bitMask = data[offset]
        offset += 1
        for bit in (f'{bitMask:08b}')[::-1]:
            if bit == '1':
                if word:
                    offset += 1
                byte = data[offset]
                offset += 1
                assetSize -= 1
                outBuffer.append(byte)
                tempBuffer[tempIndex] = byte
                tempIndex = (tempIndex + 1) & 0xFFF
                if assetSize == 0:
                    return bytes(outBuffer)
            else:
                if word:
                    offset += 1
                byte1 = data[offset]
                offset += 1

                if word:
                    offset += 1
                byte2 = data[offset]
                offset += 1
                
                num = (byte2 & 0xF) + 3
                index = byte1 + ((byte2 & 0xF0) << 4)

                for i in range(num):
                    byte = tempBuffer[(index + i) & 0xFFF]
                    assetSize -= 1
                    outBuffer.append(byte)
                    tempBuffer[tempIndex] = byte
                    tempIndex = (tempIndex + 1) & 0xFFF
                    if assetSize == 0:
                        return bytes(outBuffer)                    
    return bytes(outBuffer)

def save_image(data, name, noPal = False):
    numTiles = struct.unpack_from(">H", data, 2)[0]
    print(f"Number of tiles: {numTiles}")
    tiles = [data[4 + i * 32: 4 + (i+1) * 32] for i in range(numTiles)]
    global palValues
    if palValues == []:
        if not noPal:
            palOffset = 4 + numTiles * 32
            palette = data[palOffset : palOffset + 128]
            print(f"Palette offset: 0x{palOffset:X}")
            #calculate rgb values
            for i in range(64):
                b = palette[i * 2]
                g = (palette[i * 2 + 1] & 0xF0) >> 4
                r = palette[i * 2 + 1] & 0xF
                r *= 0x10
                g *= 0x10
                b *= 0x10
                palValues.append([r, g, b])
            ntOffset = palOffset + 128
        else:
            for i in range(64):
                b = i * 3
                g = i * 3
                r = i * 3
                palValues.append([r, g, b])
            ntOffset = 4 + numTiles * 32
    else:
        ntOffset = 4 + numTiles * 32
    
    w, h = struct.unpack_from(">HH", data, ntOffset)
    print(f"Size: {w}x{h}")

    image = Image.new('RGB', (w * 8, h * 8))
    
    for k in range(w * h):
        d = struct.unpack_from(">H", data, ntOffset + 4 + 2 * k)[0]
        priority = (d & 0x8000) >> 15
        paletteLine = (d & 0x6000) >> 13
        vFlip = (d & 0x1000) >> 12
        hFlip = (d & 0x800) >> 11
        tileIndex = (d & 0x7FF)
        baseX = (k % w) * 8
        baseY = (k // w) * 8
        for i in range(8):
            for j in range(8):
                x = baseX + 7 - j if hFlip else baseX + j
                y = baseY + 7 - i if vFlip else baseY + i
                byteValue = tiles[tileIndex][i*4 + (j // 2)]
                value = ((byteValue & 0xF0) >> 4) if j % 2 == 0 else (byteValue & 0xF)
                image.putpixel((x, y), tuple(palValues[paletteLine * 16 + value]))
    
    image.save(f"{name}.png")


def test(romFile):
    with open(romFile, "rb") as f:
        content = f.read()
    
    imageOffsets = [0x9B494]
    global palValues
    palValues = []
    
    for offset in imageOffsets:
        data = decompress(content, offset, offset >= 0x90000)
        print(f"Unpacking image at 0x{offset:X}")
        save_image(data, "image_" + hex(offset), True)


if __name__ == "__main__" :
    test("baserom.md")