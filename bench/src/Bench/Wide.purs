-- | `bench.Wide`, in the shape the generator will emit. Written by bench/tools/wide.ts.
module Bench.Wide
  ( Wide
  , decodeWide
  , encodeWide
  , sample
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Decode (decodeMessage)
import Yoga.Protobuf.Error (DecodeError(..), failure)
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

wideFrom :: Bytes -> Int -> Int -> Either DecodeError Wide
wideFrom input start end = loop start 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false 0 "" 0.0 zero false
  where
  loop position f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
    | position >= end = Right { f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16, f17, f18, f19, f20, f21, f22, f23, f24, f25, f26, f27, f28, f29, f30, f31, f32, f33, f34, f35, f36, f37, f38, f39, f40, f41, f42, f43, f44, f45, f46, f47, f48, f49, f50 }
    | otherwise = do
        let afterTag = Wire.varintEnd input position end
        let tag = Wire.varint32 input position
        if afterTag < 0 then Left (failure afterTag position)
        else
          if tag < 264 then
            if tag < 136 then
              if tag < 72 then
                case tag of
                  8 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next (Wire.varint32 input afterTag) f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  18 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 text f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  25 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 (Wire.double input afterTag) f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  32 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 (Wire.varint64 input afterTag) f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  40 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 (Wire.bool input afterTag) f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  48 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 (Wire.varint32 input afterTag) f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  58 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 text f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  65 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 (Wire.double input afterTag) f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  tag -> do
                    let next = Wire.skip input tag afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
              else
                case tag of
                  72 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 (Wire.varint64 input afterTag) f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  80 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 (Wire.bool input afterTag) f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  88 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 (Wire.varint32 input afterTag) f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  98 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 text f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  105 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 (Wire.double input afterTag) f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  112 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 (Wire.varint64 input afterTag) f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  120 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 (Wire.bool input afterTag) f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  128 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 (Wire.varint32 input afterTag) f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  tag -> do
                    let next = Wire.skip input tag afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
            else
              if tag < 200 then
                case tag of
                  138 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 text f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  145 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 (Wire.double input afterTag) f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  152 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 (Wire.varint64 input afterTag) f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  160 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 (Wire.bool input afterTag) f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  168 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 (Wire.varint32 input afterTag) f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  178 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 text f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  185 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 (Wire.double input afterTag) f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  192 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 (Wire.varint64 input afterTag) f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  tag -> do
                    let next = Wire.skip input tag afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
              else
                case tag of
                  200 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 (Wire.bool input afterTag) f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  208 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 (Wire.varint32 input afterTag) f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  218 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 text f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  225 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 (Wire.double input afterTag) f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  232 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 (Wire.varint64 input afterTag) f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  240 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 (Wire.bool input afterTag) f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  248 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 (Wire.varint32 input afterTag) f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  258 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 text f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  tag -> do
                    let next = Wire.skip input tag afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
          else
            if tag < 392 then
              if tag < 328 then
                case tag of
                  265 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 (Wire.double input afterTag) f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  272 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 (Wire.varint64 input afterTag) f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  280 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 (Wire.bool input afterTag) f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  288 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 (Wire.varint32 input afterTag) f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  298 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 text f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  305 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 (Wire.double input afterTag) f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  312 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 (Wire.varint64 input afterTag) f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  320 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 (Wire.bool input afterTag) f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
                  tag -> do
                    let next = Wire.skip input tag afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
              else
                case tag of
                  328 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 (Wire.varint32 input afterTag) f42 f43 f44 f45 f46 f47 f48 f49 f50
                  338 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 text f43 f44 f45 f46 f47 f48 f49 f50
                  345 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 (Wire.double input afterTag) f44 f45 f46 f47 f48 f49 f50
                  352 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 (Wire.varint64 input afterTag) f45 f46 f47 f48 f49 f50
                  360 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 (Wire.bool input afterTag) f46 f47 f48 f49 f50
                  368 -> do
                    let next = Wire.varintEnd input afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 (Wire.varint32 input afterTag) f47 f48 f49 f50
                  378 -> do
                    let payload = Wire.varintEnd input afterTag end
                    let next = Wire.delimitedEnd input afterTag payload end
                    if next < 0 then Left (failure next afterTag)
                    else do
                      let text = Wire.string input payload next
                      if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                      else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 text f48 f49 f50
                  385 -> do
                    let next = Wire.fixedEnd afterTag 8 end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 (Wire.double input afterTag) f49 f50
                  tag -> do
                    let next = Wire.skip input tag afterTag end
                    if next < 0 then Left (failure next afterTag)
                    else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50
            else
              case tag of
                392 -> do
                  let next = Wire.varintEnd input afterTag end
                  if next < 0 then Left (failure next afterTag)
                  else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 (Wire.varint64 input afterTag) f50
                400 -> do
                  let next = Wire.varintEnd input afterTag end
                  if next < 0 then Left (failure next afterTag)
                  else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 (Wire.bool input afterTag)
                tag -> do
                  let next = Wire.skip input tag afterTag end
                  if next < 0 then Left (failure next afterTag)
                  else loop next f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42 f43 f44 f45 f46 f47 f48 f49 f50

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
