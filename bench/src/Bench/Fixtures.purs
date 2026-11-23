-- | The samples' bytes as other implementations wrote them, in bench/fixtures.
module Bench.Fixtures
  ( Writer(..)
  , readFixture
  ) where

import Prelude

import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)

data Writer = ProtocGenGo | ProtobufEs

-- | `bench/fixtures/<name>.bin` from protoc-gen-go, or `<name>.es.bin` from protobuf-es,
-- | relative to where the program runs, which is the repository.
readFixture :: Writer -> String -> Effect Bytes
readFixture writer name = readFileImpl ("bench/fixtures/" <> name <> suffix)
  where
  suffix = case writer of
    ProtocGenGo -> ".bin"
    ProtobufEs -> ".es.bin"

foreign import readFileImpl :: String -> Effect Bytes
