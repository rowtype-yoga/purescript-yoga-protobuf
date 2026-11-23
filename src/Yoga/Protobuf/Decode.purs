-- | What generated decoders share.
-- |
-- | A decoder for a message is a function from the input and the range its fields are in to the
-- | message. It reads one field per step of a loop whose arguments are the fields so far, so
-- | both backends run it as a loop over local variables:
-- |
-- | ```purescript
-- | innerFrom :: Bytes -> Int -> Int -> Either DecodeError Inner
-- | innerFrom input start end = loop start 0 ""
-- |   where
-- |   loop position a b
-- |     | position >= end = Right { a, b }
-- |     | otherwise = do
-- |         let afterTag = Wire.varintEnd input position end
-- |         case Wire.varint32 input position of
-- |           8 -> do
-- |             let next = Wire.varintEnd input afterTag end
-- |             if next < 0 then Left (failure next afterTag)
-- |             else loop next (Wire.varint32 input afterTag) b
-- |           …
-- | ```
module Yoga.Protobuf.Decode
  ( Reader
  , decodeMessage
  , packedInt32
  ) where

import Prelude

import Data.Either (Either)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Error (DecodeError)
import Yoga.Protobuf.Repeated (Repeated)
import Yoga.Protobuf.Repeated as Repeated
import Yoga.Protobuf.Wire as Wire

-- | Reads a message from the fields between the two positions.
type Reader a = Bytes -> Int -> Int -> Either DecodeError a

decodeMessage :: forall a. Reader a -> Bytes -> Either DecodeError a
decodeMessage read input = read input 0 (Bytes.length input)

-- | Adds the varints between `start` and `end` to `values`. `Wire.packedVarintsValid` has to
-- | have said they're whole.
packedInt32 :: Bytes -> Int -> Int -> Repeated Int -> Repeated Int
packedInt32 input start end values
  | start >= end = values
  | otherwise = packedInt32 input (Wire.varintEnd input start end) end (Repeated.snoc values (Wire.varint32 input start))
