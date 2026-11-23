-- | What generated decoders share.
-- |
-- | A decoder for a message is an uncurried function from the input and the range its fields
-- | are in to the message. It reads one field per step of a loop whose arguments are the fields
-- | so far, so both backends run it as a loop over local variables:
-- |
-- | ```purescript
-- | innerFrom :: Reader Inner
-- | innerFrom = mkFn3 \input start end -> do
-- |   let
-- |     loop position a b
-- |       | position >= end = Right { a, b }
-- |       | otherwise = do
-- |           let afterTag = Wire.varintEnd input position end
-- |           if afterTag < 0 then Left (failure afterTag position)
-- |           else case Wire.varint32 input position of
-- |             8 -> do
-- |               let next = Wire.varintEnd input afterTag end
-- |               if next < 0 then Left (failure next afterTag)
-- |               else loop next (Wire.varint32 input afterTag) b
-- |             …
-- |   loop start 0 ""
-- | ```
module Yoga.Protobuf.Decode
  ( Reader
  , Entry
  , decodeMessage
  , mapFromEntries
  , packedInt32
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either)
import Data.Foldable (foldl)
import Data.Function.Uncurried (Fn3, Fn4, mkFn3, mkFn4, runFn3, runFn4)
import Data.Int.Bits (shr)
import Data.Map as Map
import Data.Map.Internal (Map(..))
import Partial.Unsafe (unsafePartial)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Error (DecodeError)
import Yoga.Protobuf.Repeated (Repeated)
import Yoga.Protobuf.Repeated as Repeated
import Yoga.Protobuf.Wire as Wire

-- | Reads a message from the fields between two positions. Uncurried, because on JavaScript a
-- | curried call makes a closure per argument, and nested messages are read once per field.
type Reader a = Fn3 Bytes Int Int (Either DecodeError a)

decodeMessage :: forall a. Reader a -> Bytes -> Either DecodeError a
decodeMessage read input = runFn3 read input 0 (Bytes.length input)

-- | One entry of a `map<k, v>` field.
type Entry k v = { key :: k, value :: v }

-- | The map of a `map<k, v>` field's entries in the order they came, where a later entry for a
-- | key replaces an earlier one. Encoders tend to sort the entries by key, and then the map is
-- | built without comparing more than neighbours.
mapFromEntries :: forall k v. Ord k => Repeated (Entry k v) -> Map k v
mapFromEntries repeated =
  if ascending 1 then fromAscending entries
  else foldl (\entriesSoFar entry -> Map.insert entry.key entry.value entriesSoFar) Map.empty entries
  where
  entries = Repeated.freeze repeated
  count = Array.length entries
  keyAt index = (entryAt entries index).key
  ascending index
    | index >= count = true
    | keyAt (index - 1) < keyAt index = ascending (index + 1)
    | otherwise = false

-- | The balanced tree of entries whose keys ascend, built without comparing keys.
fromAscending :: forall k v. Array (Entry k v) -> Map k v
fromAscending entries = runFn3 build entries 0 (Array.length entries)

-- | The tree of the entries from `low` up to `high`. Uncurried, so that JavaScript doesn't make
-- | a closure per call.
build :: forall k v. Fn3 (Array (Entry k v)) Int Int (Map k v)
build = mkFn3 \entries low high ->
  if low >= high then Leaf
  else do
    let middle = (low + high) `shr` 1
    let left = runFn3 build entries low middle
    let right = runFn3 build entries (middle + 1) high
    let entry = entryAt entries middle
    Node (1 + heightOf left) (high - low) entry.key entry.value left right
  where
  -- The left half is never smaller than the right one, so it's never lower.
  heightOf = case _ of
    Leaf -> 0
    Node height _ _ _ _ _ -> height

entryAt :: forall k v. Array (Entry k v) -> Int -> Entry k v
entryAt entries index = unsafePartial (Array.unsafeIndex entries index)

-- | Adds the varints between `start` and `end` to `values`. `Wire.packedVarintsValid` has to
-- | have said they're whole.
packedInt32 :: Bytes -> Int -> Int -> Repeated Int -> Repeated Int
packedInt32 input start end values = runFn4 packedInt32Fn input start end values

packedInt32Fn :: Fn4 Bytes Int Int (Repeated Int) (Repeated Int)
packedInt32Fn = mkFn4 \input start end values -> do
  let
    fill position filled
      | position >= end = filled
      | otherwise = fill (Wire.varintEnd input position end) (Repeated.snoc filled (Wire.varint32 input position))
  fill start (Repeated.reserve values (Wire.varintCount input start end))
