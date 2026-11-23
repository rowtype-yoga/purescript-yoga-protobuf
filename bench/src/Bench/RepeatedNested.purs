-- | `bench.RepeatedNested`, written by hand the way the generator will write it.
module Bench.RepeatedNested
  ( RepeatedNested
  , decodeRepeatedNested
  , encodeRepeatedNested
  ) where

import Prelude

import Bench.Nested (Inner, innerFrom, writeInner)
import Data.Either (Either(..))
import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Decode (decodeMessage)
import Yoga.Protobuf.Error (DecodeError, failure)
import Yoga.Protobuf.Repeated as Repeated
import Yoga.Protobuf.Wire as Wire
import Yoga.Protobuf.Writer (Writer, encodeWith)
import Yoga.Protobuf.Writer as Writer

type RepeatedNested = { items :: Array Inner }

decodeRepeatedNested :: Bytes -> Either DecodeError RepeatedNested
decodeRepeatedNested input = decodeMessage repeatedNestedFrom input

encodeRepeatedNested :: RepeatedNested -> Bytes
encodeRepeatedNested message = encodeWith writeRepeatedNested message

repeatedNestedFrom :: Bytes -> Int -> Int -> Either DecodeError RepeatedNested
repeatedNestedFrom input start end = loop start Repeated.empty
  where
  loop position items
    | position >= end = Right { items: Repeated.freeze items }
    | otherwise = do
        let afterTag = Wire.varintEnd input position end
        if afterTag < 0 then Left (failure afterTag position)
        else case Wire.varint32 input position of
          10 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else case innerFrom input payload next of
              Left error -> Left error
              Right value -> loop next (Repeated.snoc items value)
          tag -> do
            let next = Wire.skip input tag afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next items

writeRepeatedNested :: Writer -> RepeatedNested -> Effect Unit
writeRepeatedNested writer message =
  Writer.eachDescending message.items \item -> do
    mark <- Writer.written writer
    writeInner writer item
    Writer.lengthSince writer mark
    Writer.tag writer 10
