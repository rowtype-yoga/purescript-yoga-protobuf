-- | How the generated `bench.Msg` decoder handles messages, good and broken.
module Test.Bench.NestedSpec where

import Prelude

import Bench.Samples as Samples
import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Int64 as Int64
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Error (DecodeError(..))
import Yoga.Protobuf.Generated.Bench (decodeMsg, defaultMsg, encodeMsg)

spec :: Spec Unit
spec = describe "bench.Msg" do
  describe "round trips" do
    it "decodes what it encodes" do
      decodeMsg (encodeMsg Samples.nested) `shouldEqual` Right Samples.nested
    it "encodes the default message to no bytes" do
      encodeMsg defaultMsg `shouldEqual` Bytes.empty
    it "decodes no bytes to the default message" do
      decodeMsg Bytes.empty `shouldEqual` Right defaultMsg
    it "round trips a negative int64 and negative int32s" do
      let message = Samples.nested { big = negate (Int64.fromInt 5), id = -7, nums = [ -1, 0, 1 ] }
      decodeMsg (encodeMsg message) `shouldEqual` Right message
    it "round trips non-ASCII text" do
      let message = Samples.nested { name = "naïve ☃ 𝄞", labels = [ "é", "" ] }
      decodeMsg (encodeMsg message) `shouldEqual` Right message

  describe "fields it reads like protoc-gen-go does" do
    it "skips fields it doesn't know" do
      decodeMsg (fromArray (Bytes.toArray (encodeMsg Samples.nested) <> [ 0x78, 0x05, 0x7a, 0x01, 0x61 ]))
        `shouldEqual` Right Samples.nested
    it "reads repeated int32s that aren't packed" do
      map _.nums (decodeMsg (fromArray [ 0x20, 0x01, 0x20, 0x02 ])) `shouldEqual` Right [ 1, 2 ]
    it "lets the last value of a field win" do
      map _.id (decodeMsg (fromArray [ 0x08, 0x01, 0x08, 0x02 ])) `shouldEqual` Right 2

  describe "broken input" do
    it "fails or decodes, but never crashes, on every prefix of the sample" do
      let bytes = Bytes.toArray (encodeMsg Samples.nested)
      for_ (Array.range 0 (Array.length bytes - 1)) \count ->
        case decodeMsg (fromArray (Array.take count bytes)) of
          Right _ -> pure unit
          Left (Truncated _) -> pure unit
          Left error -> fail ("prefix of " <> show count <> " bytes: " <> show error)
    it "says where a string runs past the end" do
      decodeMsg (fromArray [ 0x1a, 0x05, 0x61 ]) `shouldEqual` Left (Truncated 1)
    it "says where a varint is longer than ten bytes" do
      decodeMsg (fromArray ([ 0x08 ] <> Array.replicate 10 0xff <> [ 0x01 ])) `shouldEqual` Left (MalformedVarint 1)
    it "says where a string isn't UTF-8" do
      decodeMsg (fromArray [ 0x1a, 0x02, 0xc0, 0x80 ]) `shouldEqual` Left (InvalidUtf8 2)
    it "says where a nested message's string isn't UTF-8" do
      decodeMsg (fromArray [ 0x2a, 0x04, 0x12, 0x02, 0xc0, 0x80 ]) `shouldEqual` Left (InvalidUtf8 4)
    it "says where a map key isn't UTF-8" do
      decodeMsg (fromArray [ 0x32, 0x04, 0x0a, 0x02, 0xed, 0xa0 ]) `shouldEqual` Left (InvalidUtf8 4)
    it "says where a packed field's last varint is cut off" do
      decodeMsg (fromArray [ 0x22, 0x01, 0x80 ]) `shouldEqual` Left (MalformedVarint 2)
    it "rejects field number 0" do
      decodeMsg (fromArray [ 0x00 ]) `shouldEqual` Left (InvalidWireType 1)
    it "rejects wire type 7" do
      decodeMsg (fromArray [ 0x0f, 0x00 ]) `shouldEqual` Left (InvalidWireType 1)
    it "says where a double runs past the end" do
      decodeMsg (fromArray [ 0x39, 0x00, 0x00 ]) `shouldEqual` Left (Truncated 1)
  where
  fromArray = Bytes.fromArray
