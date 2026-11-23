-- | The samples' bytes as other implementations wrote them, in bench/fixtures.
module Bench.Fixtures
  ( Writer(..)
  , readFixture
  , readFile
  , suffixOf
  ) where

import Prelude

import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)

data Writer = ProtocGenGo | ProtobufEs

-- | `bench/fixtures/<name>.bin` from protoc-gen-go, or `<name>.es.bin` from protobuf-es,
-- | relative to where the program runs, which is the repository.
readFixture :: Writer -> String -> Effect Bytes
readFixture writer name = readFile ("bench/fixtures/" <> name <> suffixOf writer)

-- | `.bin` for protoc-gen-go's bytes, `.es.bin` for protobuf-es's.
suffixOf :: Writer -> String
suffixOf = case _ of
  ProtocGenGo -> ".bin"
  ProtobufEs -> ".es.bin"

-- | The file at the path, relative to where the program runs.
readFile :: String -> Effect Bytes
readFile path = readFileImpl path

foreign import readFileImpl :: String -> Effect Bytes
