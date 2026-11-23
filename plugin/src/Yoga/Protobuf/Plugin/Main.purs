-- | protoc-gen-purescript on Bun: reads protoc's request from standard input and writes the
-- | response to standard output.
module Yoga.Protobuf.Plugin.Main
  ( main
  ) where

import Prelude

import Effect (Effect)
import Yoga.Protobuf.Plugin.Generate (run)
import Yoga.Protobuf.Plugin.Stdio as Stdio

main :: Effect Unit
main = do
  request <- Stdio.readAll
  Stdio.writeAll (run request)
