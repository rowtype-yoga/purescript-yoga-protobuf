-- | purescript-go's bytes and ours are both a `[]byte`, but Iris won't `unsafeCoerce` one
-- | foreign type to another, so this hands them over.
module Yoga.Protobuf.Plugin.GoBytes
  ( toYoga
  , fromYoga
  ) where

import Go.Bytes as Go

import Yoga.Protobuf.Bytes (Bytes)

-- | The same bytes, as this library's.
toYoga :: Go.Bytes -> Bytes
toYoga bytes = toYogaImpl bytes

foreign import toYogaImpl :: Go.Bytes -> Bytes

-- | The same bytes, as purescript-go's.
fromYoga :: Bytes -> Go.Bytes
fromYoga bytes = fromYogaImpl bytes

foreign import fromYogaImpl :: Bytes -> Go.Bytes
