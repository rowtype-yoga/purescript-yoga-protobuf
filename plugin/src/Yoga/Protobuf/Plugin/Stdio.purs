-- | Standard input and output as bytes, for the plugin on Bun. On Go, `Go.OS.Stdio` does this.
module Yoga.Protobuf.Plugin.Stdio
  ( readAll
  , writeAll
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)

import Yoga.Protobuf.Bytes (Bytes)

-- | Everything on standard input, once it has ended.
readAll :: Effect Bytes
readAll = readAllImpl

foreign import readAllImpl :: Effect Bytes

-- | Writes all of the bytes, however many writes that takes.
writeAll :: Bytes -> Effect Unit
writeAll bytes = runEffectFn1 writeAllImpl bytes

foreign import writeAllImpl :: EffectFn1 Bytes Unit
