-- | `bench.Wide`, in the shape the generator will emit. Written by bench/tools/wide.ts.
module Bench.Wide
  ( Wide
  , decodeWide
  , encodeWide
  , sample
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Function.Uncurried (mkFn3, runFn3, runFn4)
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Decode (Reader, decodeMessage)
import Yoga.Protobuf.Error (DecodeError(..), failure)
import Yoga.Protobuf.Fields as Fields
import Yoga.Protobuf.Wire as Wire
import Yoga.Protobuf.Writer (Writer, encodeWith)
import Yoga.Protobuf.Writer as Writer

type Wide =
  { f1 :: Int
  , f2 :: String
  , f3 :: Number
  , f4 :: Int64
  , f5 :: Boolean
  , f6 :: Int
  , f7 :: String
  , f8 :: Number
  , f9 :: Int64
  , f10 :: Boolean
  , f11 :: Int
  , f12 :: String
  , f13 :: Number
  , f14 :: Int64
  , f15 :: Boolean
  , f16 :: Int
  , f17 :: String
  , f18 :: Number
  , f19 :: Int64
  , f20 :: Boolean
  , f21 :: Int
  , f22 :: String
  , f23 :: Number
  , f24 :: Int64
  , f25 :: Boolean
  , f26 :: Int
  , f27 :: String
  , f28 :: Number
  , f29 :: Int64
  , f30 :: Boolean
  , f31 :: Int
  , f32 :: String
  , f33 :: Number
  , f34 :: Int64
  , f35 :: Boolean
  , f36 :: Int
  , f37 :: String
  , f38 :: Number
  , f39 :: Int64
  , f40 :: Boolean
  , f41 :: Int
  , f42 :: String
  , f43 :: Number
  , f44 :: Int64
  , f45 :: Boolean
  , f46 :: Int
  , f47 :: String
  , f48 :: Number
  , f49 :: Int64
  , f50 :: Boolean
  }

decodeWide :: Bytes -> Either DecodeError Wide
decodeWide input = decodeMessage wideFrom input

encodeWide :: Wide -> Bytes
encodeWide wide = encodeWith writeWide wide

sample :: Wide
sample =
  { f1: 1007
  , f2: "field 2"
  , f3: 3.25
  , f4: Int64.fromInt 4 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f5: true
  , f6: 6007
  , f7: "field 7"
  , f8: 8.25
  , f9: Int64.fromInt 9 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f10: true
  , f11: 11007
  , f12: "field 12"
  , f13: 13.25
  , f14: Int64.fromInt 14 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f15: true
  , f16: 16007
  , f17: "field 17"
  , f18: 18.25
  , f19: Int64.fromInt 19 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f20: true
  , f21: 21007
  , f22: "field 22"
  , f23: 23.25
  , f24: Int64.fromInt 24 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f25: true
  , f26: 26007
  , f27: "field 27"
  , f28: 28.25
  , f29: Int64.fromInt 29 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f30: true
  , f31: 31007
  , f32: "field 32"
  , f33: 33.25
  , f34: Int64.fromInt 34 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f35: true
  , f36: 36007
  , f37: "field 37"
  , f38: 38.25
  , f39: Int64.fromInt 39 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f40: true
  , f41: 41007
  , f42: "field 42"
  , f43: 43.25
  , f44: Int64.fromInt 44 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f45: true
  , f46: 46007
  , f47: "field 47"
  , f48: 48.25
  , f49: Int64.fromInt 49 * Int64.fromInt 100000 * Int64.fromInt 100000
  , f50: true
  }

wideFrom :: Reader Wide
wideFrom = mkFn3 \input start end -> do
  let
    scan position fields
      | position >= end = Right fields
      | otherwise = do
          let afterTag = Wire.varintEnd input position end
          if afterTag < 0 then Left (failure afterTag position)
          else do
            let tag = Wire.varint32 input position
            let next = Wire.skip input tag afterTag end
            if next < 0 then Left (failure next afterTag)
            else scan next (Fields.note fields wireTypes tag afterTag)
  case scan start (Fields.new input 51) of
    Left error -> Left error
    Right fields -> do
      let
        wide =
          { f1: runFn3 Fields.int32 input fields 1
          , f2: runFn4 Fields.string input fields 2 end
          , f3: runFn3 Fields.double input fields 3
          , f4: runFn3 Fields.int64 input fields 4
          , f5: runFn3 Fields.bool input fields 5
          , f6: runFn3 Fields.int32 input fields 6
          , f7: runFn4 Fields.string input fields 7 end
          , f8: runFn3 Fields.double input fields 8
          , f9: runFn3 Fields.int64 input fields 9
          , f10: runFn3 Fields.bool input fields 10
          , f11: runFn3 Fields.int32 input fields 11
          , f12: runFn4 Fields.string input fields 12 end
          , f13: runFn3 Fields.double input fields 13
          , f14: runFn3 Fields.int64 input fields 14
          , f15: runFn3 Fields.bool input fields 15
          , f16: runFn3 Fields.int32 input fields 16
          , f17: runFn4 Fields.string input fields 17 end
          , f18: runFn3 Fields.double input fields 18
          , f19: runFn3 Fields.int64 input fields 19
          , f20: runFn3 Fields.bool input fields 20
          , f21: runFn3 Fields.int32 input fields 21
          , f22: runFn4 Fields.string input fields 22 end
          , f23: runFn3 Fields.double input fields 23
          , f24: runFn3 Fields.int64 input fields 24
          , f25: runFn3 Fields.bool input fields 25
          , f26: runFn3 Fields.int32 input fields 26
          , f27: runFn4 Fields.string input fields 27 end
          , f28: runFn3 Fields.double input fields 28
          , f29: runFn3 Fields.int64 input fields 29
          , f30: runFn3 Fields.bool input fields 30
          , f31: runFn3 Fields.int32 input fields 31
          , f32: runFn4 Fields.string input fields 32 end
          , f33: runFn3 Fields.double input fields 33
          , f34: runFn3 Fields.int64 input fields 34
          , f35: runFn3 Fields.bool input fields 35
          , f36: runFn3 Fields.int32 input fields 36
          , f37: runFn4 Fields.string input fields 37 end
          , f38: runFn3 Fields.double input fields 38
          , f39: runFn3 Fields.int64 input fields 39
          , f40: runFn3 Fields.bool input fields 40
          , f41: runFn3 Fields.int32 input fields 41
          , f42: runFn4 Fields.string input fields 42 end
          , f43: runFn3 Fields.double input fields 43
          , f44: runFn3 Fields.int64 input fields 44
          , f45: runFn3 Fields.bool input fields 45
          , f46: runFn3 Fields.int32 input fields 46
          , f47: runFn4 Fields.string input fields 47 end
          , f48: runFn3 Fields.double input fields 48
          , f49: runFn3 Fields.int64 input fields 49
          , f50: runFn3 Fields.bool input fields 50
          }
      if false then Left (InvalidUtf8 0)
      else if wide.f2 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 2 end))
      else if wide.f7 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 7 end))
      else if wide.f12 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 12 end))
      else if wide.f17 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 17 end))
      else if wide.f22 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 22 end))
      else if wide.f27 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 27 end))
      else if wide.f32 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 32 end))
      else if wide.f37 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 37 end))
      else if wide.f42 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 42 end))
      else if wide.f47 == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields 47 end))
      else Right wide

wireTypes :: Array Int
wireTypes = [ -1, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0 ]

writeWide :: Writer -> Wide -> Effect Unit
writeWide writer wide = do
  when (wide.f50) do
    Writer.bool writer wide.f50
    Writer.tag writer 400
  when (wide.f49 /= zero) do
    Writer.int64 writer wide.f49
    Writer.tag writer 392
  when (wide.f48 /= 0.0) do
    Writer.double writer wide.f48
    Writer.tag writer 385
  when (wide.f47 /= "") do
    Writer.string writer wide.f47
    Writer.tag writer 378
  when (wide.f46 /= 0) do
    Writer.int32 writer wide.f46
    Writer.tag writer 368
  when (wide.f45) do
    Writer.bool writer wide.f45
    Writer.tag writer 360
  when (wide.f44 /= zero) do
    Writer.int64 writer wide.f44
    Writer.tag writer 352
  when (wide.f43 /= 0.0) do
    Writer.double writer wide.f43
    Writer.tag writer 345
  when (wide.f42 /= "") do
    Writer.string writer wide.f42
    Writer.tag writer 338
  when (wide.f41 /= 0) do
    Writer.int32 writer wide.f41
    Writer.tag writer 328
  when (wide.f40) do
    Writer.bool writer wide.f40
    Writer.tag writer 320
  when (wide.f39 /= zero) do
    Writer.int64 writer wide.f39
    Writer.tag writer 312
  when (wide.f38 /= 0.0) do
    Writer.double writer wide.f38
    Writer.tag writer 305
  when (wide.f37 /= "") do
    Writer.string writer wide.f37
    Writer.tag writer 298
  when (wide.f36 /= 0) do
    Writer.int32 writer wide.f36
    Writer.tag writer 288
  when (wide.f35) do
    Writer.bool writer wide.f35
    Writer.tag writer 280
  when (wide.f34 /= zero) do
    Writer.int64 writer wide.f34
    Writer.tag writer 272
  when (wide.f33 /= 0.0) do
    Writer.double writer wide.f33
    Writer.tag writer 265
  when (wide.f32 /= "") do
    Writer.string writer wide.f32
    Writer.tag writer 258
  when (wide.f31 /= 0) do
    Writer.int32 writer wide.f31
    Writer.tag writer 248
  when (wide.f30) do
    Writer.bool writer wide.f30
    Writer.tag writer 240
  when (wide.f29 /= zero) do
    Writer.int64 writer wide.f29
    Writer.tag writer 232
  when (wide.f28 /= 0.0) do
    Writer.double writer wide.f28
    Writer.tag writer 225
  when (wide.f27 /= "") do
    Writer.string writer wide.f27
    Writer.tag writer 218
  when (wide.f26 /= 0) do
    Writer.int32 writer wide.f26
    Writer.tag writer 208
  when (wide.f25) do
    Writer.bool writer wide.f25
    Writer.tag writer 200
  when (wide.f24 /= zero) do
    Writer.int64 writer wide.f24
    Writer.tag writer 192
  when (wide.f23 /= 0.0) do
    Writer.double writer wide.f23
    Writer.tag writer 185
  when (wide.f22 /= "") do
    Writer.string writer wide.f22
    Writer.tag writer 178
  when (wide.f21 /= 0) do
    Writer.int32 writer wide.f21
    Writer.tag writer 168
  when (wide.f20) do
    Writer.bool writer wide.f20
    Writer.tag writer 160
  when (wide.f19 /= zero) do
    Writer.int64 writer wide.f19
    Writer.tag writer 152
  when (wide.f18 /= 0.0) do
    Writer.double writer wide.f18
    Writer.tag writer 145
  when (wide.f17 /= "") do
    Writer.string writer wide.f17
    Writer.tag writer 138
  when (wide.f16 /= 0) do
    Writer.int32 writer wide.f16
    Writer.tag writer 128
  when (wide.f15) do
    Writer.bool writer wide.f15
    Writer.tag writer 120
  when (wide.f14 /= zero) do
    Writer.int64 writer wide.f14
    Writer.tag writer 112
  when (wide.f13 /= 0.0) do
    Writer.double writer wide.f13
    Writer.tag writer 105
  when (wide.f12 /= "") do
    Writer.string writer wide.f12
    Writer.tag writer 98
  when (wide.f11 /= 0) do
    Writer.int32 writer wide.f11
    Writer.tag writer 88
  when (wide.f10) do
    Writer.bool writer wide.f10
    Writer.tag writer 80
  when (wide.f9 /= zero) do
    Writer.int64 writer wide.f9
    Writer.tag writer 72
  when (wide.f8 /= 0.0) do
    Writer.double writer wide.f8
    Writer.tag writer 65
  when (wide.f7 /= "") do
    Writer.string writer wide.f7
    Writer.tag writer 58
  when (wide.f6 /= 0) do
    Writer.int32 writer wide.f6
    Writer.tag writer 48
  when (wide.f5) do
    Writer.bool writer wide.f5
    Writer.tag writer 40
  when (wide.f4 /= zero) do
    Writer.int64 writer wide.f4
    Writer.tag writer 32
  when (wide.f3 /= 0.0) do
    Writer.double writer wide.f3
    Writer.tag writer 25
  when (wide.f2 /= "") do
    Writer.string writer wide.f2
    Writer.tag writer 18
  when (wide.f1 /= 0) do
    Writer.int32 writer wide.f1
    Writer.tag writer 8
