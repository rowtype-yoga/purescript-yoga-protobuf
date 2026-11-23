const TRUNCATED = -1;
const MALFORMED_VARINT = -2;
const INVALID_WIRE_TYPE = -3;
const MAX_GROUP_DEPTH = 100;
const LONG_STRING = 32;

export const varintEndImpl = (input, position, end) => {
  if (position < end && input[position] < 0x80) return position + 1;
  if (position + 1 < end && input[position + 1] < 0x80) return position + 2;
  return varintEndSlow(input, position, end);
};

const varintEndSlow = (input, position, end) => {
  const limit = Math.min(end, position + 10);
  for (let index = position; index < limit; index++) {
    if (input[index] < 0x80) return index + 1;
  }
  return limit === end && end - position < 10 ? TRUNCATED : MALFORMED_VARINT;
};

export const delimitedEndImpl = (input, position, start, end) => {
  if (start < 0) return start;
  const first = input[position];
  if (first < 0x80) return first <= end - start ? start + first : TRUNCATED;
  const length = lengthOf(input, position, start);
  return length >= 0 && length <= end - start ? start + length : TRUNCATED;
};

const lengthOf = (input, position, start) => {
  if (start - position > 5) return -1;
  let length = 0;
  for (let index = start - 1; index >= position; index--) length = length * 128 + (input[index] & 0x7f);
  return length > 0x7fffffff ? -1 : length;
};

export const skipImpl = (input, tag, position, end) => skipField(input, tag, position, end, 0);

const skipField = (input, tag, position, end, depth) => {
  if (tag >>> 3 === 0) return INVALID_WIRE_TYPE;
  switch (tag & 7) {
    case 0:
      return varintEndImpl(input, position, end);
    case 1:
      return end - position < 8 ? TRUNCATED : position + 8;
    case 2:
      return delimitedEndImpl(input, position, varintEndImpl(input, position, end), end);
    case 3:
      return skipGroup(input, tag >>> 3, position, end, depth + 1);
    case 5:
      return end - position < 4 ? TRUNCATED : position + 4;
    default:
      return INVALID_WIRE_TYPE;
  }
};

const skipGroup = (input, fieldNumber, position, end, depth) => {
  if (depth > MAX_GROUP_DEPTH) return INVALID_WIRE_TYPE;
  let at = position;
  for (;;) {
    const afterTag = varintEndImpl(input, at, end);
    if (afterTag < 0) return afterTag;
    const tag = varint32Impl(input, at);
    if ((tag & 7) === 4) return tag >>> 3 === fieldNumber ? afterTag : INVALID_WIRE_TYPE;
    at = skipField(input, tag, afterTag, end, depth);
    if (at < 0) return at;
  }
};

export const varint32Impl = (input, position) => {
  let byte = input[position];
  if (byte < 0x80) return byte;
  let result = byte & 0x7f;
  byte = input[position + 1];
  result |= (byte & 0x7f) << 7;
  if (byte < 0x80) return result;
  byte = input[position + 2];
  result |= (byte & 0x7f) << 14;
  if (byte < 0x80) return result;
  byte = input[position + 3];
  result |= (byte & 0x7f) << 21;
  if (byte < 0x80) return result;
  return result | (input[position + 4] << 28);
};

export const varint64Impl = (fromLowHigh, input, position) => {
  let low = 0;
  let index = position;
  for (let shift = 0; shift < 28; shift += 7) {
    const byte = input[index++];
    low |= (byte & 0x7f) << shift;
    if (!(byte >= 0x80)) return fromLowHigh(low, 0);
  }
  const middle = input[index++];
  low |= (middle & 0x7f) << 28;
  let high = (middle & 0x7f) >>> 4;
  if (!(middle >= 0x80)) return fromLowHigh(low, high);
  for (let shift = 3; shift < 32; shift += 7) {
    const byte = input[index++];
    high |= (byte & 0x7f) << shift;
    if (!(byte >= 0x80)) break;
  }
  return fromLowHigh(low, high);
};

export const boolImpl = (input, position) => {
  for (let index = position; index < position + 10; index++) {
    const byte = input[index];
    if ((byte & 0x7f) !== 0) return true;
    if (!(byte >= 0x80)) return false;
  }
  return false;
};

export const fixed32Impl = (input, position) =>
  input[position] | (input[position + 1] << 8) | (input[position + 2] << 16) | (input[position + 3] << 24);

export const fixed64Impl = (fromLowHigh, input, position) =>
  fromLowHigh(fixed32Impl(input, position), fixed32Impl(input, position + 4));

const scratch = new ArrayBuffer(8);
const scratchBytes = new Uint8Array(scratch);
const scratchFloat = new Float32Array(scratch);
const scratchDouble = new Float64Array(scratch);

export const floatImpl = (input, position) => {
  scratchBytes[0] = input[position];
  scratchBytes[1] = input[position + 1];
  scratchBytes[2] = input[position + 2];
  scratchBytes[3] = input[position + 3];
  return scratchFloat[0];
};

export const doubleImpl = (input, position) => {
  for (let index = 0; index < 8; index++) scratchBytes[index] = input[position + index];
  return scratchDouble[0];
};

export const invalidUtf8Impl = "\uD800";

const fatalDecoder = new TextDecoder("utf-8", { fatal: true });

export const stringImpl = (input, start, end) => {
  if (end - start > LONG_STRING) {
    try {
      return fatalDecoder.decode(input.subarray(start, end));
    } catch {
      return invalidUtf8Impl;
    }
  }
  let text = "";
  let index = start;
  while (index < end) {
    const first = input[index];
    if (first < 0x80) {
      text += String.fromCharCode(first);
      index += 1;
      continue;
    }
    const width = sequenceWidth(input, index, end);
    if (width === 0) return invalidUtf8Impl;
    text += String.fromCodePoint(codePoint(input, index, width));
    index += width;
  }
  return text;
};

export const utf8ValidImpl = (input, start, end) => {
  let index = start;
  while (index < end) {
    if (input[index] < 0x80) {
      index += 1;
      continue;
    }
    const width = sequenceWidth(input, index, end);
    if (width === 0) return false;
    index += width;
  }
  return true;
};

// How many bytes the UTF-8 sequence at `index` takes, or 0 if it isn't one. Rejects overlong
// encodings, surrogates and code points past U+10FFFF, as Go's utf8.Valid does.
const sequenceWidth = (input, index, end) => {
  const first = input[index];
  const second = index + 1 < end ? input[index + 1] : 0;
  if (first >= 0xc2 && first <= 0xdf) return isContinuation(second) ? 2 : 0;
  const third = index + 2 < end ? input[index + 2] : 0;
  if (first >= 0xe0 && first <= 0xef) {
    const low = first === 0xe0 ? 0xa0 : 0x80;
    const high = first === 0xed ? 0x9f : 0xbf;
    return second >= low && second <= high && isContinuation(third) ? 3 : 0;
  }
  const fourth = index + 3 < end ? input[index + 3] : 0;
  if (first >= 0xf0 && first <= 0xf4) {
    const low = first === 0xf0 ? 0x90 : 0x80;
    const high = first === 0xf4 ? 0x8f : 0xbf;
    return second >= low && second <= high && isContinuation(third) && isContinuation(fourth) ? 4 : 0;
  }
  return 0;
};

const isContinuation = (byte) => (byte & 0xc0) === 0x80;

const codePoint = (input, index, width) => {
  const first = input[index];
  if (width === 2) return ((first & 0x1f) << 6) | (input[index + 1] & 0x3f);
  if (width === 3) return ((first & 0x0f) << 12) | ((input[index + 1] & 0x3f) << 6) | (input[index + 2] & 0x3f);
  return ((first & 0x07) << 18) | ((input[index + 1] & 0x3f) << 12) | ((input[index + 2] & 0x3f) << 6) | (input[index + 3] & 0x3f);
};

export const bytesImpl = (input, start, end) => input.slice(start, end);

export const packedVarintsValidImpl = (input, start, end) => {
  let run = 0;
  for (let index = start; index < end; index++) {
    if (input[index] < 0x80) run = 0;
    else if (++run >= 10) return false;
  }
  return run === 0;
};
