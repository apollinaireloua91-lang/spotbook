/**
 * Pure Deno QR Code → PNG generator.
 *
 * Uses qrcode-generator (pure JS, no canvas) + pako (zlib compression)
 * to produce a valid PNG buffer suitable for email embedding.
 *
 * Why not SVG? Most email clients (Gmail, Outlook) strip inline SVG
 * and poorly render <img src="*.svg">. PNG is universally supported.
 */

import qrcodegen from "https://esm.sh/qrcode-generator@1.4.4";
import { deflate } from "https://esm.sh/pako@2.1.0";

// ── CRC32 (required for PNG chunks) ──────────────────────────────────

const CRC_TABLE = new Uint32Array(256);
for (let i = 0; i < 256; i++) {
  let c = i;
  for (let j = 0; j < 8; j++) {
    c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  }
  CRC_TABLE[i] = c >>> 0;
}

function crc32(buf: Uint8Array): number {
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    crc = CRC_TABLE[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

// ── PNG chunk builder ────────────────────────────────────────────────

function pngChunk(type: string, data: Uint8Array): Uint8Array {
  const typeBytes = new TextEncoder().encode(type);
  const chunk = new Uint8Array(4 + 4 + data.length + 4);
  const view = new DataView(chunk.buffer);

  view.setUint32(0, data.length, false);
  chunk.set(typeBytes, 4);
  chunk.set(data, 8);

  const crcInput = new Uint8Array(4 + data.length);
  crcInput.set(typeBytes, 0);
  crcInput.set(data, 4);
  view.setUint32(8 + data.length, crc32(crcInput), false);

  return chunk;
}

// ── Public API ───────────────────────────────────────────────────────

/**
 * Generate a PNG image of a QR code.
 *
 * @param text   Data to encode (e.g. "ticketId|qrHash")
 * @param scale  Pixels per QR module (default 8 → crisp on retina)
 * @param margin QR quiet zone in modules (default 2)
 * @returns      PNG file as Uint8Array
 */
export function generateQrPng(
  text: string,
  scale = 8,
  margin = 2,
): Uint8Array {
  // 1. Generate QR matrix — type 0 = auto version, 'M' = 15% error correction
  const qr = qrcodegen(0, "M");
  qr.addData(text);
  qr.make();

  const moduleCount = qr.getModuleCount();
  const size = (moduleCount + margin * 2) * scale;

  // 2. Build grayscale pixel data with PNG filter bytes
  //    Color type 0 (grayscale), bit depth 8
  //    Each row: 1 filter byte (0x00 = None) + `size` pixel bytes
  const rowBytes = size + 1;
  const rawData = new Uint8Array(size * rowBytes);

  for (let y = 0; y < size; y++) {
    rawData[y * rowBytes] = 0; // filter: None
    for (let x = 0; x < size; x++) {
      const mx = Math.floor(x / scale) - margin;
      const my = Math.floor(y / scale) - margin;
      const isDark =
        mx >= 0 &&
        my >= 0 &&
        mx < moduleCount &&
        my < moduleCount &&
        qr.isDark(my, mx);
      rawData[y * rowBytes + 1 + x] = isDark ? 0 : 255;
    }
  }

  // 3. Compress with zlib (pako.deflate = zlib format, required by PNG)
  const compressed = deflate(rawData);

  // 4. Build PNG file
  const signature = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR — 13 bytes: width(4) height(4) bitDepth(1) colorType(1) compression(1) filter(1) interlace(1)
  const ihdrData = new Uint8Array(13);
  const ihdrView = new DataView(ihdrData.buffer);
  ihdrView.setUint32(0, size, false);
  ihdrView.setUint32(4, size, false);
  ihdrData[8] = 8; // bit depth
  ihdrData[9] = 0; // color type: grayscale
  ihdrData[10] = 0; // compression: deflate
  ihdrData[11] = 0; // filter: adaptive
  ihdrData[12] = 0; // interlace: none
  const ihdr = pngChunk("IHDR", ihdrData);

  const idat = pngChunk("IDAT", compressed);
  const iend = pngChunk("IEND", new Uint8Array(0));

  // 5. Concatenate all parts
  const png = new Uint8Array(
    signature.length + ihdr.length + idat.length + iend.length,
  );
  let offset = 0;
  png.set(signature, offset);
  offset += signature.length;
  png.set(ihdr, offset);
  offset += ihdr.length;
  png.set(idat, offset);
  offset += idat.length;
  png.set(iend, offset);

  return png;
}
