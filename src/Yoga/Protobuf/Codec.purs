-- | A message type's decoder and encoder together.
module Yoga.Protobuf.Codec
  ( Codec(..)
  , codec
  , decode
  , encode
  ) where

import Prelude

import Data.Either (Either)
import Data.Newtype (class Newtype, un)
import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Decode (Reader, decodeMessage)
import Yoga.Protobuf.Error (DecodeError)
import Yoga.Protobuf.Writer (Writer, encodeWith)

newtype Codec a = Codec { read :: Reader a, write :: Writer -> a -> Effect Unit }

derive instance Newtype (Codec a) _

codec :: forall a. Reader a -> (Writer -> a -> Effect Unit) -> Codec a
codec read write = Codec { read, write }

decode :: forall a. Codec a -> Bytes -> Either DecodeError a
decode messageCodec input = decodeMessage (un Codec messageCodec).read input

encode :: forall a. Codec a -> a -> Bytes
encode messageCodec value = encodeWith (un Codec messageCodec).write value
