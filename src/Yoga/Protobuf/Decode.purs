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
  , Entry
  , decodeMessage
  , mapFromEntries
  , packedInt32
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either)
import Data.Foldable (foldl)
import Data.Map as Map
import Data.Map.Internal (Map(..))
import Partial.Unsafe (unsafePartial)
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
fromAscending entries = build 0 (Array.length entries)
  where
  build low high
    | low >= high = Leaf
    | otherwise = do
        let middle = (low + high) `div` 2
        let left = build low middle
        let right = build (middle + 1) high
        let entry = entryAt entries middle
        Node (1 + heightOf left) (high - low) entry.key entry.value left right
  -- The left half is never smaller than the right one, so it's never lower.
  heightOf = case _ of
    Leaf -> 0
    Node height _ _ _ _ _ -> height

entryAt :: forall k v. Array (Entry k v) -> Int -> Entry k v
entryAt entries index = unsafePartial (Array.unsafeIndex entries index)

-- | Adds the varints between `start` and `end` to `values`. `Wire.packedVarintsValid` has to
-- | have said they're whole.
packedInt32 :: Bytes -> Int -> Int -> Repeated Int -> Repeated Int
packedInt32 input start end values = fill start (Repeated.reserve values (Wire.varintCount input start end))
  where
  fill position filled
    | position >= end = filled
    | otherwise = fill (Wire.varintEnd input position end) (Repeated.snoc filled (Wire.varint32 input position))
