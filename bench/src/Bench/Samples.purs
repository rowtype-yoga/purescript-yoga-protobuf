-- | The messages every implementation in the benchmark encodes and decodes.
module Bench.Samples
  ( nested
  , repeatedNested
  , wide
  ) where

import Prelude

import Data.Array (range)
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Yoga.Protobuf.Generated.Bench (Msg, RepeatedNested, Wide)

-- | A bit of everything in 164 bytes.
nested :: Msg
nested =
  { id: 12345
  , big: Int64.fromInt 1234567 * Int64.fromInt 1000000 + Int64.fromInt 890123
  , name: "hello world, this is a name"
  , nums: range 1 20
  , inner: Just { a: 7, b: "inner string" }
  , tags: Map.fromFoldable (map (\index -> ("key" <> show index) /\ (index * 100)) (range 1 5))
  , score: 3.14159
  , ok: true
  , labels: [ "alpha", "beta", "gamma" ]
  }

-- | A thousand small nested messages.
repeatedNested :: RepeatedNested
repeatedNested = { items: map (\index -> { a: index, b: "item " <> show index }) (range 0 999) }

-- | Field `n` is `n` thousand and seven, `"field n"`, `n.25`, `n` times ten billion or `true`,
-- | going round the five types.
wide :: Wide
wide =
  { f1: 1007
  , f2: "field 2"
  , f3: 3.25
  , f4: tenBillion 4
  , f5: true
  , f6: 6007
  , f7: "field 7"
  , f8: 8.25
  , f9: tenBillion 9
  , f10: true
  , f11: 11007
  , f12: "field 12"
  , f13: 13.25
  , f14: tenBillion 14
  , f15: true
  , f16: 16007
  , f17: "field 17"
  , f18: 18.25
  , f19: tenBillion 19
  , f20: true
  , f21: 21007
  , f22: "field 22"
  , f23: 23.25
  , f24: tenBillion 24
  , f25: true
  , f26: 26007
  , f27: "field 27"
  , f28: 28.25
  , f29: tenBillion 29
  , f30: true
  , f31: 31007
  , f32: "field 32"
  , f33: 33.25
  , f34: tenBillion 34
  , f35: true
  , f36: 36007
  , f37: "field 37"
  , f38: 38.25
  , f39: tenBillion 39
  , f40: true
  , f41: 41007
  , f42: "field 42"
  , f43: 43.25
  , f44: tenBillion 44
  , f45: true
  , f46: 46007
  , f47: "field 47"
  , f48: 48.25
  , f49: tenBillion 49
  , f50: true
  }
  where
  tenBillion :: Int -> Int64
  tenBillion times = Int64.fromInt times * Int64.fromInt 100000 * Int64.fromInt 100000
