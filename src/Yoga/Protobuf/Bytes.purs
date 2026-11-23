module Yoga.Protobuf.Bytes
  ( Bytes
  , length
  , fromArray
  , toArray
  , empty
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, runFn2)

-- | Encoded protocol buffer bytes: a `Uint8Array` on JavaScript, a `[]byte` on Go.
-- | Bytes never change once made, so a decoder may keep views into them.
foreign import data Bytes :: Type

instance Eq Bytes where
  eq left right = runFn2 eqImpl left right

foreign import eqImpl :: Fn2 Bytes Bytes Boolean

instance Show Bytes where
  show bytes = "(fromArray " <> show (toArray bytes) <> ")"

length :: Bytes -> Int
length bytes = lengthImpl bytes

foreign import lengthImpl :: Bytes -> Int

-- | Bytes from numbers between 0 and 255. Other numbers keep their lowest 8 bits.
fromArray :: Array Int -> Bytes
fromArray numbers = fromArrayImpl numbers

foreign import fromArrayImpl :: Array Int -> Bytes

toArray :: Bytes -> Array Int
toArray bytes = toArrayImpl bytes

foreign import toArrayImpl :: Bytes -> Array Int

empty :: Bytes
empty = emptyImpl

foreign import emptyImpl :: Bytes
