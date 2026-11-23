-- | Writing the protocol buffer wire format back to front.
-- |
-- | An encoder writes a message's last field first and each field's tag after its value. A
-- | nested message is written before its length, which is then simply how much it wrote, so
-- | nothing has to be measured before it's written.
-- |
-- | ```purescript
-- | writeInner :: Writer -> Inner -> Effect Unit
-- | writeInner writer inner = do
-- |   when (inner.b /= "") do
-- |     Writer.string writer inner.b
-- |     Writer.tag writer 18
-- |   when (inner.a /= 0) do
-- |     Writer.int32 writer inner.a
-- |     Writer.tag writer 8
-- | ```
module Yoga.Protobuf.Writer
  ( Writer
  , encodeWith
  , written
  , lengthSince
  , tag
  , int32
  , uint32
  , int64
  , sint32
  , sint64
  , bool
  , fixed32
  , fixed64
  , float
  , double
  , string
  , bytes
  , eachDescending
  ) where

import Prelude

import Data.Array as Array
import Data.Int.Bits (shl, shr, xor)
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Effect (Effect, forE)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, runEffectFn1, runEffectFn2, runEffectFn3)
import Effect.Unsafe (unsafePerformEffect)
import Partial.Unsafe (unsafePartial)
import Yoga.Protobuf.Bytes (Bytes)

-- | Where an encoder writes. Encoders borrow one through `encodeWith` and never keep it.
foreign import data Writer :: Type

-- | The bytes `write` writes for `value`.
encodeWith :: forall a. (Writer -> a -> Effect Unit) -> a -> Bytes
encodeWith write value = unsafePerformEffect do
  writer <- acquire
  write writer value
  finish writer
  where
  acquire = acquireImpl
  finish writer = runEffectFn1 finishImpl writer

foreign import acquireImpl :: Effect Writer
foreign import finishImpl :: EffectFn1 Writer Bytes

-- | How many bytes have been written so far.
written :: Writer -> Effect Int
written writer = runEffectFn1 writtenImpl writer

foreign import writtenImpl :: EffectFn1 Writer Int

-- | Writes how many bytes were written since `written` said `mark`: the length of a nested
-- | message or packed field.
lengthSince :: Writer -> Int -> Effect Unit
lengthSince writer mark = runEffectFn2 lengthSinceImpl writer mark

foreign import lengthSinceImpl :: EffectFn2 Writer Int Unit

-- | A field's tag: its number shifted left by three, or'd with its wire type.
tag :: Writer -> Int -> Effect Unit
tag writer value = uint32 writer value

-- | `int32` and `enum` fields. Negative numbers take ten bytes, as they would as `int64`.
int32 :: Writer -> Int -> Effect Unit
int32 writer value = runEffectFn2 int32Impl writer value

foreign import int32Impl :: EffectFn2 Writer Int Unit

-- | `uint32` fields, whose bits are in an `Int`.
uint32 :: Writer -> Int -> Effect Unit
uint32 writer value = runEffectFn2 uint32Impl writer value

foreign import uint32Impl :: EffectFn2 Writer Int Unit

-- | `int64` and `uint64` fields.
int64 :: Writer -> Int64 -> Effect Unit
int64 writer value = runEffectFn3 int64Impl writer (Int64.lowBits value) (Int64.highBits value)

foreign import int64Impl :: EffectFn3 Writer Int Int Unit

sint32 :: Writer -> Int -> Effect Unit
sint32 writer value = uint32 writer ((value `shl` 1) `xor` (value `shr` 31))

sint64 :: Writer -> Int64 -> Effect Unit
sint64 writer value = int64 writer (Int64.shl value one `Int64.xor` Int64.shr value (Int64.fromInt 63))

bool :: Writer -> Boolean -> Effect Unit
bool writer value = uint32 writer (if value then 1 else 0)

-- | `fixed32` and `sfixed32` fields, whose bits are in an `Int`.
fixed32 :: Writer -> Int -> Effect Unit
fixed32 writer value = runEffectFn2 fixed32Impl writer value

foreign import fixed32Impl :: EffectFn2 Writer Int Unit

fixed64 :: Writer -> Int64 -> Effect Unit
fixed64 writer value = runEffectFn3 fixed64Impl writer (Int64.lowBits value) (Int64.highBits value)

foreign import fixed64Impl :: EffectFn3 Writer Int Int Unit

float :: Writer -> Number -> Effect Unit
float writer value = runEffectFn2 floatImpl writer value

foreign import floatImpl :: EffectFn2 Writer Number Unit

double :: Writer -> Number -> Effect Unit
double writer value = runEffectFn2 doubleImpl writer value

foreign import doubleImpl :: EffectFn2 Writer Number Unit

-- | The text as UTF-8, then its length. A lone surrogate becomes U+FFFD, as with `TextEncoder`.
string :: Writer -> String -> Effect Unit
string writer value = runEffectFn2 stringImpl writer value

foreign import stringImpl :: EffectFn2 Writer String Unit

-- | The bytes, then their length.
bytes :: Writer -> Bytes -> Effect Unit
bytes writer value = runEffectFn2 bytesImpl writer value

foreign import bytesImpl :: EffectFn2 Writer Bytes Unit

-- | Runs `write` on the values from the last to the first, the order a back-to-front writer
-- | needs to put them out first to last.
eachDescending :: forall a. Array a -> (a -> Effect Unit) -> Effect Unit
eachDescending values write = forE 0 count \index -> write (valueAt (count - 1 - index))
  where
  count = Array.length values
  valueAt index = unsafePartial (Array.unsafeIndex values index)
