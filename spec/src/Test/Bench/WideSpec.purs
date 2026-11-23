-- | How the two-step `bench.Wide` decoder handles messages, good and broken.
module Test.Bench.WideSpec where

import Prelude

import Bench.Wide (decodeWide, encodeWide)
import Bench.Wide as Wide
import Data.Either (Either(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Error (DecodeError(..))

spec :: Spec Unit
spec = describe "bench.Wide" do
  it "decodes what it encodes" do
    decodeWide (encodeWide Wide.sample) `shouldEqual` Right Wide.sample
  it "lets the last value of a field win" do
    map _.f1 (decodeWide (Bytes.fromArray [ 0x08, 0x01, 0x08, 0x02 ])) `shouldEqual` Right 2
  it "skips a field whose wire type isn't the one the message has for it" do
    map _.f1 (decodeWide (Bytes.fromArray [ 0x0a, 0x01, 0x61 ])) `shouldEqual` Right 0
  it "skips field numbers the message doesn't have" do
    map _.f1 (decodeWide (Bytes.fromArray [ 0x98, 0x06, 0x01, 0x08, 0x05 ])) `shouldEqual` Right 5
  it "says where a string isn't UTF-8" do
    decodeWide (Bytes.fromArray [ 0x08, 0x01, 0x12, 0x02, 0xc0, 0x80 ]) `shouldEqual` Left (InvalidUtf8 4)
  it "says where a field runs past the end" do
    decodeWide (Bytes.fromArray [ 0x12, 0x05, 0x61 ]) `shouldEqual` Left (Truncated 1)
