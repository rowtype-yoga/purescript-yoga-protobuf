-- | Reading the protocol buffer wire format, one value at a time.
-- |
-- | A decoder walks the input with positions. The functions that find where something ends,
-- | `varintEnd`, `fixedEnd`, `delimitedEnd` and `skip`, check the input and answer with a
-- | negative code when it's broken, which `Yoga.Protobuf.Error.failure` turns into a
-- | `DecodeError`. The functions that read a value trust that its end was checked first.
module Yoga.Protobuf.Wire
  ( varintEnd
  , fixedEnd
  , delimitedEnd
  , skip
  , varint32
  , varint64
  , bool
  , sint32
  , sint64
  , fixed32
  , fixed64
  , float
  , double
  , string
  , invalidUtf8
  , utf8Valid
  , bytes
  , packedVarintsValid
  , zigzag32
  , zigzag64
  , truncated
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, Fn3, Fn4, mkFn2, runFn2, runFn3, runFn4)
import Data.Int.Bits (xor, zshr, (.&.))
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Yoga.Protobuf.Bytes (Bytes)

-- | Where the varint at `position` ends, if it ends before `end` and within ten bytes.
-- | Otherwise `-1` when the input ends first, `-2` when the varint is longer than ten bytes.
varintEnd :: Bytes -> Int -> Int -> Int
varintEnd input position end = runFn3 varintEndImpl input position end

foreign import varintEndImpl :: Fn3 Bytes Int Int Int

-- | Where a fixed-width value of `width` bytes at `position` ends, or `-1` past `end`.
fixedEnd :: Int -> Int -> Int -> Int
fixedEnd position width end = if end - position < width then truncated else position + width

-- | Where the payload of a length-delimited field ends. Its length is the varint at
-- | `position`, which `varintEnd` said ends at `start`, where the payload starts.
delimitedEnd :: Bytes -> Int -> Int -> Int -> Int
delimitedEnd input position start end = runFn4 delimitedEndImpl input position start end

foreign import delimitedEndImpl :: Fn4 Bytes Int Int Int Int

-- | Where the field ends whose `tag` ends at `position`, for fields a decoder doesn't know.
-- | `-3` for a tag with field number 0 or a wire type that can't start a field.
skip :: Bytes -> Int -> Int -> Int -> Int
skip input tag position end = runFn4 skipImpl input tag position end

foreign import skipImpl :: Fn4 Bytes Int Int Int Int

-- | The lowest 32 bits of the varint at `position`: `int32`, `uint32` and `enum` fields, and tags.
varint32 :: Bytes -> Int -> Int
varint32 input position = runFn2 varint32Impl input position

foreign import varint32Impl :: Fn2 Bytes Int Int

-- | The varint at `position`: `int64` and `uint64` fields.
varint64 :: Bytes -> Int -> Int64
varint64 input position = runFn3 varint64Impl fromLowHigh input position

foreign import varint64Impl :: Fn3 (Fn2 Int Int Int64) Bytes Int Int64

bool :: Bytes -> Int -> Boolean
bool input position = runFn2 boolImpl input position

foreign import boolImpl :: Fn2 Bytes Int Boolean

sint32 :: Bytes -> Int -> Int
sint32 input position = zigzag32 (varint32 input position)

sint64 :: Bytes -> Int -> Int64
sint64 input position = zigzag64 (varint64 input position)

-- | The four little-endian bytes at `position` as `Int` bits: `fixed32` and `sfixed32` fields.
fixed32 :: Bytes -> Int -> Int
fixed32 input position = runFn2 fixed32Impl input position

foreign import fixed32Impl :: Fn2 Bytes Int Int

fixed64 :: Bytes -> Int -> Int64
fixed64 input position = runFn3 fixed64Impl fromLowHigh input position

foreign import fixed64Impl :: Fn3 (Fn2 Int Int Int64) Bytes Int Int64

float :: Bytes -> Int -> Number
float input position = runFn2 floatImpl input position

foreign import floatImpl :: Fn2 Bytes Int Number

double :: Bytes -> Int -> Number
double input position = runFn2 doubleImpl input position

foreign import doubleImpl :: Fn2 Bytes Int Number

-- | The UTF-8 text from `start` up to `end`, or `invalidUtf8` if it isn't UTF-8.
string :: Bytes -> Int -> Int -> String
string input start end = runFn3 stringImpl input start end

foreign import stringImpl :: Fn3 Bytes Int Int String

-- | A lone surrogate. No UTF-8 decodes to one, so `string` answers with it for bytes that
-- | aren't UTF-8.
invalidUtf8 :: String
invalidUtf8 = invalidUtf8Impl

foreign import invalidUtf8Impl :: String

utf8Valid :: Bytes -> Int -> Int -> Boolean
utf8Valid input start end = runFn3 utf8ValidImpl input start end

foreign import utf8ValidImpl :: Fn3 Bytes Int Int Boolean

-- | A copy of the bytes from `start` up to `end`.
bytes :: Bytes -> Int -> Int -> Bytes
bytes input start end = runFn3 bytesImpl input start end

foreign import bytesImpl :: Fn3 Bytes Int Int Bytes

-- | Whether the bytes from `start` up to `end` are whole varints of at most ten bytes each.
packedVarintsValid :: Bytes -> Int -> Int -> Boolean
packedVarintsValid input start end = runFn3 packedVarintsValidImpl input start end

foreign import packedVarintsValidImpl :: Fn3 Bytes Int Int Boolean

zigzag32 :: Int -> Int
zigzag32 n = (n `zshr` 1) `xor` negate (n .&. 1)

zigzag64 :: Int64 -> Int64
zigzag64 n = Int64.zshr n one `Int64.xor` negate (n `Int64.and` one)

truncated :: Int
truncated = -1

fromLowHigh :: Fn2 Int Int Int64
fromLowHigh = mkFn2 Int64.fromLowHighBits
