-- | The features samples, the same as in spec/fixtures/go/main.go and spec/fixtures/js/fixtures.mjs.
module Test.Features.Samples
  ( everything
  , legacy
  ) where

import Prelude

import Data.Int64 (Int64)
import Data.Int64 as Int64
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (un)
import Data.Tuple.Nested ((/\))
import Data.Variant as Variant
import Type.Proxy (Proxy(..))
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Generated.Features (Colour(..), Direction(..), Everything, Light(..), Outer_Inner_Kind(..), Tree(..), defaultEmpty, defaultScalars, defaultTree, defaultOuter_Inner)
import Yoga.Protobuf.Generated.Imported (Mood(..))
import Yoga.Protobuf.Generated.Imported as Imported
import Yoga.Protobuf.Generated.Legacy (Legacy(..), Legacy_Size(..))
import Yoga.Protobuf.Unsigned (UInt32(..), UInt64(..))

everything :: Everything
everything =
  { scalars: Just
      { aDouble: 1.5
      , aFloat: 2.25
      , anInt32: -42
      , anInt64: bits (-410065408) (-3) -- -9000000000
      , aUint32: UInt32 (-294967296) -- 4000000000
      , aUint64: UInt64 (bits (-989331456) (-104015711)) -- 18000000000000000000
      , aSint32: -7
      , aSint64: bits 1097262572 (-29) -- -123456789012
      , aFixed32: UInt32 (-1294967296) -- 3000000000
      , aFixed64: UInt64 (bits 1942892530 2874) -- 12345678901234
      , anSfixed32: -5
      , anSfixed64: bits (-1705032704) (-2) -- -6000000000
      , aBool: true
      , aString: "héllo ☃"
      , someBytes: Bytes.fromArray [ 0, 1, 2, 255 ]
      , aColour: ColourBlue
      , aLight: LightAmber
      , aDirection: EastByNortheast
      }
  , optionals: Just
      { maybeInt32: Just 0
      , maybeString: Just ""
      , maybeColour: Just ColourRed
      , maybeBytes: Nothing
      , maybeDouble: Nothing
      , maybeUint64: Just (UInt64 (Int64.fromInt 7))
      , maybeBool: Just false
      }
  , repeateds: Just
      { doubles: [ 1.5, -2.5 ]
      , floats: [ 0.5 ]
      , int32s: [ 1, -1, 300 ]
      , int64s: [ Int64.fromInt (-1), fiveBillion ]
      , uint32s: [ UInt32 1, UInt32 (-294967296) ]
      , uint64s: [ UInt64 (Int64.fromInt 1) ]
      , sint32s: [ -1, 1 ]
      , sint64s: [ Int64.fromInt (-2) ]
      , fixed32s: [ UInt32 1, UInt32 2 ]
      , fixed64s: [ UInt64 (Int64.fromInt 3) ]
      , sfixed32s: [ -4 ]
      , sfixed64s: [ Int64.fromInt (-5) ]
      , bools: [ true, false, true ]
      , strings: [ "a", "", "ü" ]
      , byteStrings: [ Bytes.fromArray [ 1 ], Bytes.empty ]
      , colours: [ ColourRed, ColourBlue, ColourUnrecognized 7 ]
      , messages: [ defaultScalars { anInt32 = 1 }, defaultScalars ]
      , unpackedInt32s: [ 1, 2 ]
      , unpackedDoubles: [ 0.25 ]
      , unpackedColours: [ ColourGreen ]
      }
  , maps: Just
      { byName: Map.fromFoldable [ "one" /\ 1, "two" /\ 2, "zero" /\ 0 ]
      , messages: Map.fromFoldable [ 1 /\ defaultScalars { aString = "x" }, 3 /\ defaultScalars ]
      , colours: Map.fromFoldable [ UInt32 (-294967296) /\ ColourBlue, UInt32 1 /\ ColourRed ]
      , byInt64: Map.fromFoldable [ Int64.fromInt (-5) /\ "minus five", fiveBillion /\ "big" ]
      , byBool: Map.fromFoldable [ false /\ Bytes.empty, true /\ Bytes.fromArray [ 9 ] ]
      , bySint32: Map.fromFoldable [ -3 /\ 0.5 ]
      , things: Map.fromFoldable [ UInt64 (Int64.fromInt 2) /\ { name: "two", mood: Happy } ]
      }
  , choice: Just
      { pick: Just (Variant.inj (Proxy :: _ "scalars") (defaultScalars { aBool = true }))
      , after: "after"
      , other: Just (Variant.inj (Proxy :: _ "blob") (Bytes.fromArray [ 7, 8 ]))
      }
  , tree: Just
      ( Tree
          { label: "root"
          , left: Just (leaf "l")
          , children: [ leaf "c1", Tree { label: "c2", left: Just (leaf "c2l"), children: [], named: Map.empty } ]
          , named: Map.fromFoldable [ "n" /\ leaf "named" ]
          }
      )
  , outer: Just
      { inner: Just { kind: KindSmall, value: 5 }
      , inners: [ defaultOuter_Inner { kind = KindLarge }, defaultOuter_Inner ]
      , kind: KindLarge
      }
  , keywords: Just { type: 1, data: "d", input: true, end: 4, module: "m", value: 6, where: 7, loop: 8, position: 9 }
  , uses: Just
      { thing: Just { name: "thing", mood: Grumpy }
      , mood: Happy
      , things: [ Imported.defaultThing { name = "a" } ]
      , empty: Just defaultEmpty
      }
  , wide: Just
      { anInt32: 1
      , aString: "two"
      , aDouble: 3.5
      , anInt64: Int64.fromInt 4
      , aBool: true
      , aUint32: UInt32 (-294967296)
      , aSint32: -7
      , aSint64: Int64.fromInt (-8)
      , aFixed32: UInt32 9
      , aFixed64: UInt64 (Int64.fromInt 10)
      , anSfixed32: -11
      , anSfixed64: Int64.fromInt (-12)
      , aFloat: 13.5
      , someBytes: Bytes.fromArray [ 14 ]
      , aColour: ColourGreen
      , aUint64: UInt64 (Int64.fromInt 16)
      , anotherInt32: 17
      , anotherString: "eighteen"
      , anotherDouble: 19.5
      , anotherInt64: Int64.fromInt 20
      , anotherBool: true
      , lastString: "thirty"
      }
  , empty: Just defaultEmpty
  }
  where
  bits :: Int -> Int -> Int64
  bits low high = Int64.fromLowHighBits low high
  fiveBillion = bits 705032704 1
  leaf label = Tree ((un Tree defaultTree) { label = label })

legacy :: Legacy
legacy = Legacy
  { id: 1
  , name: Nothing
  , packedNumbers: [ 1, 2, 3 ]
  , numbers: [ 4, 5 ]
  , next: Just (Legacy { id: 2, name: Just "second", packedNumbers: [], numbers: [], next: Nothing, part: { on: Nothing }, size: Nothing })
  , part: { on: Just true }
  , size: Just Large
  }
