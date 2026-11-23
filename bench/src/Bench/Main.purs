-- | Encodes and decodes each sample many times and prints one line per measurement:
-- | `RESULT yoga-protobuf <message> <encode|decode> <ns/op> <allocs/op>`.
-- |
-- | Before measuring, it checks that the hand-written codecs read the bytes protoc-gen-go wrote
-- | for the samples and write exactly those bytes back.
module Bench.Main where

import Prelude

import Bench.Fixtures (Writer(..), readFixture)
import Bench.Nested (decodeMsg, encodeMsg)
import Bench.RepeatedNested (decodeRepeatedNested, encodeRepeatedNested)
import Bench.Samples as Samples
import Bench.Wide (decodeWide, encodeWide)
import Bench.Wide as Wide
import Data.Array as Array
import Data.Either (Either(..))
import Data.Int (floor, toNumber)
import Data.Int64 as Int64
import Data.String as String
import Effect (Effect, forE)
import Effect.Console (log)
import Partial.Unsafe (unsafePartial)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Error (DecodeError)

main :: Effect Unit
main = do
  check "nested" (decodeMsg >>> map encodeMsg) Samples.nested encodeMsg
  check "repeated-nested" (decodeRepeatedNested >>> map encodeRepeatedNested) Samples.repeatedNested encodeRepeatedNested
  check "wide" (decodeWide >>> map encodeWide) Wide.sample encodeWide
  let nestedSamples = [ Samples.nested ]
  let nested = encodeMsg Samples.nested
  measure "nested" "encode" 200000 do
    sample <- pick nestedSamples
    sink (Bytes.length (encodeMsg sample))
  measure "nested" "decode" 200000 do
    input <- opaque nested
    case decodeMsg input of
      Right message -> sink message.id
      Left _ -> sink (-1)
  let repeatedSamples = [ Samples.repeatedNested ]
  let repeated = encodeRepeatedNested Samples.repeatedNested
  measure "repeated-nested" "encode" 2000 do
    sample <- pick repeatedSamples
    sink (Bytes.length (encodeRepeatedNested sample))
  measure "repeated-nested" "decode" 2000 do
    input <- opaque repeated
    case decodeRepeatedNested input of
      Right message -> sink (Array.length message.items)
      Left _ -> sink (-1)
  let wideSamples = [ Wide.sample ]
  let wide = encodeWide Wide.sample
  measure "wide" "encode" 200000 do
    sample <- pick wideSamples
    sink (Bytes.length (encodeWide sample))
  measure "wide" "decode" 200000 do
    input <- opaque wide
    case decodeWide input of
      Right message -> sink (String.length message.f2 + floor message.f23 + Int64.lowBits message.f49)
      Left _ -> sink (-1)

-- | Says whether `fixtures/<name>.bin`, which protoc-gen-go wrote for the sample, decodes and
-- | encodes back to the same bytes, and whether encoding the sample gives those bytes.
check :: forall a. String -> (Bytes -> Either DecodeError Bytes) -> a -> (a -> Bytes) -> Effect Unit
check name roundTrip sample encode = do
  expected <- readFixture ProtocGenGo name
  log ("CHECK " <> name <> " " <> verdict expected)
  where
  verdict expected = case roundTrip expected of
    Left error -> "decode failed: " <> show error
    Right again
      | again /= expected -> "round trip differs from protoc-gen-go"
      | encode sample /= expected -> "encoding the sample differs from protoc-gen-go"
      | otherwise -> "ok"

measure :: String -> String -> Int -> Effect Unit -> Effect Unit
measure name operation iterations run = do
  forE 0 (iterations / 10) \_ -> run
  startedAt <- now
  allocationsBefore <- allocations
  forE 0 iterations \_ -> run
  allocationsAfter <- allocations
  finishedAt <- now
  log (line ((finishedAt - startedAt) * 1000000.0) (allocationsAfter - allocationsBefore))
  where
  count = toNumber iterations
  line nanoseconds allocated =
    "RESULT yoga-protobuf-" <> backend <> " " <> name <> " " <> operation <> " "
      <> show (nanoseconds / count) <> " " <> show (allocated / count)

foreign import now :: Effect Number

-- | Heap allocations so far: Go's `runtime.MemStats.Mallocs`, 0 on JavaScript.
foreign import allocations :: Effect Number

foreign import backend :: String

-- | The only sample, but the optimizer can't tell which one it is, so a loop can't skip the
-- | work. Only an `Int` goes through `opaque`: a record would go through Go as an `any`.
pick :: forall a. Array a -> Effect a
pick samples = do
  index <- opaque 0
  pure (unsafePartial (Array.unsafeIndex samples index))

-- | Hands back the value, but hides it from the optimizer, so a loop can't skip the work.
foreign import opaque :: forall a. a -> Effect a

-- | Keeps a result alive, so a loop can't skip computing it.
foreign import sink :: Int -> Effect Unit
