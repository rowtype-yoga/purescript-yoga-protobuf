-- | Where each field of a message is, for decoders of messages with many fields.
-- |
-- | Rather than carrying every field from one step of the loop to the next, such a decoder first
-- | notes where each field's value starts, then reads the values it wants into the record:
-- |
-- | ```purescript
-- | case scan start (Fields.new input 51) of
-- |   Left error -> Left error
-- |   Right fields -> Right { f1: runFn3 Fields.int32 input fields 1, … }
-- | ```
-- |
-- | `note` changes the `Fields` it's given and hands it back, so a `Fields` must be used
-- | linearly, as a `Repeated` is.
module Yoga.Protobuf.Fields
  ( Fields
  , new
  , note
  , at
  , int32
  , int64
  , bool
  , double
  , float
  , fixed32
  , fixed64
  , bytes
  , string
  , payloadStart
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, Fn3, Fn4, mkFn3, mkFn4, runFn2, runFn4)
import Data.Int64 (Int64)

import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Wire as Wire

-- | Where the value of each field number starts: an `Int32Array` on JavaScript, a `[]int32` on Go.
foreign import data Fields :: Type

-- | Room for the fields numbered below `count`, none of them seen yet. It takes the input only
-- | so that each decode gets its own.
new :: Bytes -> Int -> Fields
new input count = runFn2 newImpl input count

foreign import newImpl :: Fn2 Bytes Int Fields

-- | Notes that the field with this `tag` has its value at `position`, if the field is one the
-- | message has, with the wire type `wireTypes` has for its number. Later fields win.
note :: Fields -> Array Int -> Int -> Int -> Fields
note fields wireTypes tag position = runFn4 noteImpl fields wireTypes tag position

foreign import noteImpl :: Fn4 Fields (Array Int) Int Int Fields

-- | Where the value of field `number` starts, or -1 if the message doesn't have it.
at :: Fields -> Int -> Int
at fields number = runFn2 atImpl fields number

foreign import atImpl :: Fn2 Fields Int Int

-- | The readers below read field `number` from where it was noted, or give its default if
-- | it wasn't. `int32`, `uint32`, `sint32` and `enum` fields, before zigzag or wrapping.
int32 :: Fn3 Bytes Fields Int Int
int32 = mkFn3 \input fields number -> do
  let position = at fields number
  if position < 0 then 0 else Wire.varint32 input position

-- | `int64`, `uint64` and `sint64` fields, before zigzag or wrapping.
int64 :: Fn3 Bytes Fields Int Int64
int64 = mkFn3 \input fields number -> do
  let position = at fields number
  if position < 0 then zero else Wire.varint64 input position

-- | `bool` fields.
bool :: Fn3 Bytes Fields Int Boolean
bool = mkFn3 \input fields number -> do
  let position = at fields number
  position >= 0 && Wire.bool input position

-- | `double` fields.
double :: Fn3 Bytes Fields Int Number
double = mkFn3 \input fields number -> do
  let position = at fields number
  if position < 0 then 0.0 else Wire.double input position

-- | `float` fields.
float :: Fn3 Bytes Fields Int Number
float = mkFn3 \input fields number -> do
  let position = at fields number
  if position < 0 then 0.0 else Wire.float input position

-- | `fixed32` and `sfixed32` fields, as `Int` bits.
fixed32 :: Fn3 Bytes Fields Int Int
fixed32 = mkFn3 \input fields number -> do
  let position = at fields number
  if position < 0 then 0 else Wire.fixed32 input position

-- | `fixed64` and `sfixed64` fields, as `Int64` bits.
fixed64 :: Fn3 Bytes Fields Int Int64
fixed64 = mkFn3 \input fields number -> do
  let position = at fields number
  if position < 0 then zero else Wire.fixed64 input position

-- | A copy of a `bytes` field's payload.
bytes :: Fn4 Bytes Fields Int Int Bytes
bytes = mkFn4 \input fields number end -> do
  let position = at fields number
  if position < 0 then Bytes.empty
  else do
    let start = Wire.varintEnd input position end
    Wire.bytes input start (Wire.delimitedEnd input position start end)

-- | The text of field `number`, or `Wire.invalidUtf8` if it isn't UTF-8.
string :: Fn4 Bytes Fields Int Int String
string = mkFn4 \input fields number end -> do
  let position = at fields number
  if position < 0 then ""
  else do
    let start = Wire.varintEnd input position end
    Wire.string input start (Wire.delimitedEnd input position start end)

-- | Where the payload of length-delimited field `number` starts: where to say its text isn't UTF-8.
payloadStart :: Bytes -> Fields -> Int -> Int -> Int
payloadStart input fields number end = Wire.varintEnd input (at fields number) end
