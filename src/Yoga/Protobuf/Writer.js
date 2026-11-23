const INITIAL_CAPACITY = 1024;
const SHORT_STRING = 42;

class Buffer {
  constructor() {
    this.bytes = new Uint8Array(INITIAL_CAPACITY);
    this.position = INITIAL_CAPACITY;
  }
}

// One writer is kept for the next encode, so encoding a message allocates only its result.
let spare = new Buffer();

export const acquireImpl = (capacity) => {
  let writer = spare;
  if (writer === null) writer = new Buffer();
  spare = null;
  if (writer.bytes.length < capacity) writer.bytes = new Uint8Array(capacity);
  writer.position = writer.bytes.length;
  return writer;
};

// JavaScript's writes make room as they go, so they never overflow.
export const overflowedImpl = (writer) => false;

export const capacityImpl = (writer) => writer.bytes.length;

export const finishImpl = (writer) => {
  const result = writer.bytes.slice(writer.position);
  spare = writer;
  return result;
};

export const writtenImpl = (writer) => writer.bytes.length - writer.position;

const reserve = (writer, count) => {
  if (writer.position >= count) return;
  const used = writer.bytes.length - writer.position;
  const capacity = Math.max(writer.bytes.length * 2, used + count);
  const grown = new Uint8Array(capacity);
  grown.set(writer.bytes.subarray(writer.position), capacity - used);
  writer.bytes = grown;
  writer.position = capacity - used;
};

export const lengthSinceImpl = (writer, mark) => uint32Impl(writer, writer.bytes.length - writer.position - mark);

export const uint32Impl = (writer, value) => {
  if (value >>> 0 < 0x80) {
    if (writer.position < 1) reserve(writer, 1);
    writer.bytes[--writer.position] = value;
    return;
  }
  reserve(writer, 5);
  let rest = value >>> 0;
  const size = rest < 0x4000 ? 2 : rest < 0x200000 ? 3 : rest < 0x10000000 ? 4 : 5;
  const bytes = writer.bytes;
  let at = (writer.position -= size);
  while (rest >= 0x80) {
    bytes[at++] = (rest & 0x7f) | 0x80;
    rest >>>= 7;
  }
  bytes[at] = rest;
};

export const int32Impl = (writer, value) => {
  if (value >= 0) uint32Impl(writer, value);
  else int64Impl(writer, value, -1);
};

export const int64Impl = (writer, low, high) => {
  if (high === 0) {
    uint32Impl(writer, low);
    return;
  }
  reserve(writer, 10);
  let lowBits = low >>> 0;
  let highBits = high >>> 0;
  const size = varint64Size(lowBits, highBits);
  const bytes = writer.bytes;
  let at = (writer.position -= size);
  for (let index = 1; index < size; index++) {
    bytes[at++] = (lowBits & 0x7f) | 0x80;
    lowBits = ((lowBits >>> 7) | (highBits << 25)) >>> 0;
    highBits >>>= 7;
  }
  bytes[at] = lowBits;
};

const varint64Size = (low, high) => {
  let size = 1;
  while (high !== 0 || low >= 0x80) {
    low = ((low >>> 7) | (high << 25)) >>> 0;
    high >>>= 7;
    size++;
  }
  return size;
};

export const fixed32Impl = (writer, value) => {
  reserve(writer, 4);
  const at = (writer.position -= 4);
  const bytes = writer.bytes;
  bytes[at] = value;
  bytes[at + 1] = value >>> 8;
  bytes[at + 2] = value >>> 16;
  bytes[at + 3] = value >>> 24;
};

export const fixed64Impl = (writer, low, high) => {
  fixed32Impl(writer, high);
  fixed32Impl(writer, low);
};

const scratch = new ArrayBuffer(8);
const scratchBytes = new Uint8Array(scratch);
const scratchFloat = new Float32Array(scratch);
const scratchDouble = new Float64Array(scratch);

export const floatImpl = (writer, value) => {
  reserve(writer, 4);
  scratchFloat[0] = value;
  const at = (writer.position -= 4);
  const bytes = writer.bytes;
  for (let index = 0; index < 4; index++) bytes[at + index] = scratchBytes[index];
};

export const doubleImpl = (writer, value) => {
  reserve(writer, 8);
  scratchDouble[0] = value;
  const at = (writer.position -= 8);
  const bytes = writer.bytes;
  for (let index = 0; index < 8; index++) bytes[at + index] = scratchBytes[index];
};

const encoder = new TextEncoder();

export const stringImpl = (writer, text) => {
  const units = text.length;
  if (units <= SHORT_STRING) writeShortString(writer, text, units);
  else writeLongString(writer, text, units);
};

// At most three bytes per UTF-16 unit, so the length of a short string fits in one byte.
const writeShortString = (writer, text, units) => {
  reserve(writer, units * 3 + 1);
  const size = utf8Length(text, units);
  const bytes = writer.bytes;
  let at = (writer.position -= size);
  for (let index = 0; index < units; index++) {
    let unit = text.charCodeAt(index);
    if (unit < 0x80) {
      bytes[at++] = unit;
    } else if (unit < 0x800) {
      bytes[at++] = 0xc0 | (unit >> 6);
      bytes[at++] = 0x80 | (unit & 0x3f);
    } else {
      if (unit >= 0xd800 && unit <= 0xdfff) {
        const next = index + 1 < units ? text.charCodeAt(index + 1) : 0;
        if (unit <= 0xdbff && next >= 0xdc00 && next <= 0xdfff) {
          const point = 0x10000 + ((unit - 0xd800) << 10) + (next - 0xdc00);
          index++;
          bytes[at++] = 0xf0 | (point >> 18);
          bytes[at++] = 0x80 | ((point >> 12) & 0x3f);
          bytes[at++] = 0x80 | ((point >> 6) & 0x3f);
          bytes[at++] = 0x80 | (point & 0x3f);
          continue;
        }
        unit = 0xfffd;
      }
      bytes[at++] = 0xe0 | (unit >> 12);
      bytes[at++] = 0x80 | ((unit >> 6) & 0x3f);
      bytes[at++] = 0x80 | (unit & 0x3f);
    }
  }
  bytes[--writer.position] = size;
};

const utf8Length = (text, units) => {
  let size = 0;
  for (let index = 0; index < units; index++) {
    const unit = text.charCodeAt(index);
    if (unit < 0x80) size += 1;
    else if (unit < 0x800) size += 2;
    else if (unit >= 0xd800 && unit <= 0xdbff && index + 1 < units && isLowSurrogate(text.charCodeAt(index + 1))) {
      size += 4;
      index++;
    } else size += 3;
  }
  return size;
};

const isLowSurrogate = (unit) => unit >= 0xdc00 && unit <= 0xdfff;

// Encodes as far to the front as the longest encoding needs, then moves the bytes to the end.
const writeLongString = (writer, text, units) => {
  reserve(writer, units * 3 + 5);
  const start = writer.position - units * 3;
  const { written } = encoder.encodeInto(text, writer.bytes.subarray(start, writer.position));
  writer.bytes.copyWithin(writer.position - written, start, start + written);
  writer.position -= written;
  uint32Impl(writer, written);
};

export const bytesImpl = (writer, value) => {
  reserve(writer, value.length + 5);
  writer.position -= value.length;
  writer.bytes.set(value, writer.position);
  uint32Impl(writer, value.length);
};
