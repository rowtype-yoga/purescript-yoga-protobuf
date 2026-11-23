-- | `bench.Inner` and `bench.Msg`, written by hand the way the generator will write them.
module Bench.Nested
  ( Inner
  , Msg
  , decodeInner
  , decodeMsg
  , encodeInner
  , encodeMsg
  , innerFrom
  , writeInner
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Int64 (Int64)
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Decode (Entry, decodeMessage, mapFromEntries, packedInt32)
import Yoga.Protobuf.Error (DecodeError(..), failure)
import Yoga.Protobuf.Repeated as Repeated
import Yoga.Protobuf.Wire as Wire
import Yoga.Protobuf.Writer (Writer, encodeWith)
import Yoga.Protobuf.Writer as Writer

type Inner = { a :: Int, b :: String }

type Msg =
  { id :: Int
  , big :: Int64
  , name :: String
  , nums :: Array Int
  , inner :: Maybe Inner
  , tags :: Map String Int
  , score :: Number
  , ok :: Boolean
  , labels :: Array String
  }

decodeInner :: Bytes -> Either DecodeError Inner
decodeInner input = decodeMessage innerFrom input

encodeInner :: Inner -> Bytes
encodeInner inner = encodeWith writeInner inner

decodeMsg :: Bytes -> Either DecodeError Msg
decodeMsg input = decodeMessage msgFrom input

encodeMsg :: Msg -> Bytes
encodeMsg msg = encodeWith writeMsg msg

innerFrom :: Bytes -> Int -> Int -> Either DecodeError Inner
innerFrom input start end = loop start 0 ""
  where
  loop position a b
    | position >= end = Right { a, b }
    | otherwise = do
        let afterTag = Wire.varintEnd input position end
        if afterTag < 0 then Left (failure afterTag position)
        else case Wire.varint32 input position of
          8 -> do
            let next = Wire.varintEnd input afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next (Wire.varint32 input afterTag) b
          18 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else do
              let text = Wire.string input payload next
              if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
              else loop next a text
          tag -> do
            let next = Wire.skip input tag afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next a b

msgFrom :: Bytes -> Int -> Int -> Either DecodeError Msg
msgFrom input start end = loop start 0 zero "" Repeated.empty Nothing Repeated.empty 0.0 false Repeated.empty
  where
  loop position id big name nums inner tags score ok labels
    | position >= end = Right
        { id
        , big
        , name
        , nums: Repeated.freeze nums
        , inner
        , tags: mapFromEntries tags
        , score
        , ok
        , labels: Repeated.freeze labels
        }
    | otherwise = do
        let afterTag = Wire.varintEnd input position end
        if afterTag < 0 then Left (failure afterTag position)
        else case Wire.varint32 input position of
          8 -> do
            let next = Wire.varintEnd input afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next (Wire.varint32 input afterTag) big name nums inner tags score ok labels
          16 -> do
            let next = Wire.varintEnd input afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next id (Wire.varint64 input afterTag) name nums inner tags score ok labels
          26 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else do
              let text = Wire.string input payload next
              if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
              else loop next id big text nums inner tags score ok labels
          32 -> do
            let next = Wire.varintEnd input afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next id big name (Repeated.snoc nums (Wire.varint32 input afterTag)) inner tags score ok labels
          34 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else if not (Wire.packedVarintsValid input payload next) then Left (MalformedVarint payload)
            else loop next id big name (packedInt32 input payload next nums) inner tags score ok labels
          42 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else case innerFrom input payload next of
              Left error -> Left error
              Right value -> loop next id big name nums (Just value) tags score ok labels
          50 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else case tagsEntryFrom input payload next of
              Left error -> Left error
              Right entry -> loop next id big name nums inner (Repeated.snoc tags entry) score ok labels
          57 -> do
            let next = Wire.fixedEnd afterTag 8 end
            if next < 0 then Left (failure next afterTag)
            else loop next id big name nums inner tags (Wire.double input afterTag) ok labels
          64 -> do
            let next = Wire.varintEnd input afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next id big name nums inner tags score (Wire.bool input afterTag) labels
          74 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else do
              let text = Wire.string input payload next
              if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
              else loop next id big name nums inner tags score ok (Repeated.snoc labels text)
          tag -> do
            let next = Wire.skip input tag afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next id big name nums inner tags score ok labels

-- | The `map<string, int32>` entry between `start` and `end`.
type TagsEntry = Entry String Int

tagsEntryFrom :: Bytes -> Int -> Int -> Either DecodeError TagsEntry
tagsEntryFrom input start end = loop start "" 0
  where
  loop position key value
    | position >= end = Right { key, value }
    | otherwise = do
        let afterTag = Wire.varintEnd input position end
        if afterTag < 0 then Left (failure afterTag position)
        else case Wire.varint32 input position of
          10 -> do
            let payload = Wire.varintEnd input afterTag end
            let next = Wire.delimitedEnd input afterTag payload end
            if next < 0 then Left (failure next afterTag)
            else do
              let text = Wire.string input payload next
              if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
              else loop next text value
          16 -> do
            let next = Wire.varintEnd input afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next key (Wire.varint32 input afterTag)
          tag -> do
            let next = Wire.skip input tag afterTag end
            if next < 0 then Left (failure next afterTag)
            else loop next key value

writeInner :: Writer -> Inner -> Effect Unit
writeInner writer inner = do
  when (inner.b /= "") do
    Writer.string writer inner.b
    Writer.tag writer 18
  when (inner.a /= 0) do
    Writer.int32 writer inner.a
    Writer.tag writer 8

writeMsg :: Writer -> Msg -> Effect Unit
writeMsg writer msg = do
  Writer.eachDescending msg.labels \label -> do
    Writer.string writer label
    Writer.tag writer 74
  when msg.ok do
    Writer.bool writer true
    Writer.tag writer 64
  when (msg.score /= 0.0) do
    Writer.double writer msg.score
    Writer.tag writer 57
  Writer.eachEntryDescending msg.tags \key value -> do
    mark <- Writer.written writer
    Writer.int32 writer value
    Writer.tag writer 16
    Writer.string writer key
    Writer.tag writer 10
    Writer.lengthSince writer mark
    Writer.tag writer 50
  case msg.inner of
    Nothing -> pure unit
    Just inner -> do
      mark <- Writer.written writer
      writeInner writer inner
      Writer.lengthSince writer mark
      Writer.tag writer 42
  when (not (Array.null msg.nums)) do
    mark <- Writer.written writer
    Writer.eachDescending msg.nums \number -> Writer.int32 writer number
    Writer.lengthSince writer mark
    Writer.tag writer 34
  when (msg.name /= "") do
    Writer.string writer msg.name
    Writer.tag writer 26
  when (msg.big /= zero) do
    Writer.int64 writer msg.big
    Writer.tag writer 16
  when (msg.id /= 0) do
    Writer.int32 writer msg.id
    Writer.tag writer 8
