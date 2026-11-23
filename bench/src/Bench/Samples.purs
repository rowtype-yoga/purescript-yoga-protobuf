-- | The messages every implementation in the benchmark encodes and decodes.
module Bench.Samples
  ( nested
  , repeatedNested
  ) where

import Prelude

import Bench.Nested (Msg)
import Bench.RepeatedNested (RepeatedNested)
import Data.Array (range)
import Data.Int64 as Int64
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))

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

repeatedNested :: RepeatedNested
repeatedNested = { items: map (\index -> { a: index, b: "item " <> show index }) (range 0 999) }
