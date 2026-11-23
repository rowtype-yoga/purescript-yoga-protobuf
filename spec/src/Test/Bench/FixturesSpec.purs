-- | The hand-written codecs against the bytes other implementations wrote for the samples.
module Test.Bench.FixturesSpec where

import Prelude

import Bench.Fixtures (Writer(..), readFixture)
import Bench.Nested (decodeMsg, encodeMsg)
import Bench.RepeatedNested (decodeRepeatedNested, encodeRepeatedNested)
import Bench.Samples as Samples
import Bench.Wide (decodeWide, encodeWide)
import Bench.Wide as Wide
import Data.Either (Either(..))
import Effect.Class (liftEffect)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "the samples' bytes from other implementations" do
  describe "Nested" do
    it "decodes protoc-gen-go's bytes to the sample" do
      bytes <- readFixture ProtocGenGo "nested" # liftEffect
      decodeMsg bytes `shouldEqual` Right Samples.nested
    it "decodes protobuf-es's bytes, whose map entries aren't sorted, to the sample" do
      bytes <- readFixture ProtobufEs "nested" # liftEffect
      decodeMsg bytes `shouldEqual` Right Samples.nested
    it "encodes the sample to protoc-gen-go's bytes" do
      bytes <- readFixture ProtocGenGo "nested" # liftEffect
      encodeMsg Samples.nested `shouldEqual` bytes

  describe "RepeatedNested" do
    it "decodes protoc-gen-go's bytes to the sample" do
      bytes <- readFixture ProtocGenGo "repeated-nested" # liftEffect
      decodeRepeatedNested bytes `shouldEqual` Right Samples.repeatedNested
    it "decodes protobuf-es's bytes to the sample" do
      bytes <- readFixture ProtobufEs "repeated-nested" # liftEffect
      decodeRepeatedNested bytes `shouldEqual` Right Samples.repeatedNested
    it "encodes the sample to protoc-gen-go's bytes" do
      bytes <- readFixture ProtocGenGo "repeated-nested" # liftEffect
      encodeRepeatedNested Samples.repeatedNested `shouldEqual` bytes

  describe "Wide" do
    it "decodes protoc-gen-go's bytes to the sample" do
      bytes <- readFixture ProtocGenGo "wide" # liftEffect
      decodeWide bytes `shouldEqual` Right Wide.sample
    it "decodes protobuf-es's bytes to the sample" do
      bytes <- readFixture ProtobufEs "wide" # liftEffect
      decodeWide bytes `shouldEqual` Right Wide.sample
    it "encodes the sample to protoc-gen-go's bytes" do
      bytes <- readFixture ProtocGenGo "wide" # liftEffect
      encodeWide Wide.sample `shouldEqual` bytes
