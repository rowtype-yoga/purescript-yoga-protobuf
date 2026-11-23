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

-- | How to read a message from the bytes between two positions and write it back to front.
newtype Codec a = Codec { read :: Reader a, write :: Writer -> a -> Effect Unit }

derive instance Newtype (Codec a) _

-- | The codec of a reader and a writer, which generated code makes for each message.
codec :: forall a. Reader a -> (Writer -> a -> Effect Unit) -> Codec a
codec read write = Codec { read, write }

-- | The message the bytes encode, or where they're broken.
decode :: forall a. Codec a -> Bytes -> Either DecodeError a
decode messageCodec input = decodeMessage (un Codec messageCodec).read input

-- | The message's encoding.
encode :: forall a. Codec a -> a -> Bytes
encode messageCodec value = encodeWith (un Codec messageCodec).write value
