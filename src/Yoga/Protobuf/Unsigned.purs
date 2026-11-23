-- | `uint32`, `fixed32`, `uint64` and `fixed64` values, as the bits of a signed number.
-- |
-- | `UInt32 (-1)` is 4294967295. They compare as unsigned numbers, so maps with unsigned keys
-- | come out in the order other implementations sort them.
module Yoga.Protobuf.Unsigned
  ( UInt32(..)
  , UInt64(..)
  ) where

import Prelude

import Data.Int.Bits (shl, xor)
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Data.Newtype (class Newtype)

newtype UInt32 = UInt32 Int

derive instance Newtype UInt32 _
derive instance Eq UInt32

instance Ord UInt32 where
  compare (UInt32 left) (UInt32 right) = compare (flipSign left) (flipSign right)
    where
    flipSign bits = bits `xor` signBit

instance Show UInt32 where
  show (UInt32 bits) = "(UInt32 " <> show bits <> ")"

newtype UInt64 = UInt64 Int64

derive instance Newtype UInt64 _
derive instance Eq UInt64

instance Ord UInt64 where
  compare (UInt64 left) (UInt64 right) = compare (flipSign left) (flipSign right)
    where
    flipSign bits = bits `Int64.xor` Int64.fromLowHighBits 0 signBit

signBit :: Int
signBit = 1 `shl` 31

instance Show UInt64 where
  show (UInt64 bits) = "(UInt64 " <> show bits <> ")"
