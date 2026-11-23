-- | The code protoc-gen-purescript generates for spec/proto/features.proto and legacy.proto.
module Test.Features.FeaturesSpec where

import Prelude

import Bench.Fixtures (Writer(..), readFile, suffixOf)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Int64 as Int64
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (un)
import Data.Tuple.Nested ((/\))
import Data.Variant as Variant
import Effect.Class (liftEffect)
import Test.Features.Samples as Samples
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Type.Proxy (Proxy(..))
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Error (DecodeError(..))
import Yoga.Protobuf.Generated.Features (Colour(..), Direction(..), Light(..), Tree(..), decodeChoice, decodeEverything, decodeKeywords, decodeMaps, decodeRepeateds, decodeScalars, decodeTree, decodeWide, defaultChoice, defaultEverything, defaultOptionals, defaultRepeateds, defaultScalars, defaultTree, encodeChoice, encodeEverything, encodeKeywords, encodeOptionals, encodeRepeateds, encodeScalars, encodeTree, fromColour, toColour)
import Yoga.Protobuf.Generated.Legacy (Legacy(..), Legacy_Size(..), decodeLegacy, encodeLegacy)
import Yoga.Protobuf.TwoStep.Features as TwoStep
import Yoga.Protobuf.Unsigned (UInt32(..), UInt64(..))

spec :: Spec Unit
spec = describe "generated code" do
  describe "against protoc-gen-go and protobuf-es" do
    it "decodes protoc-gen-go's bytes for everything to the sample" do
      bytes <- fixture ProtocGenGo "everything"
      decodeEverything bytes `shouldEqual` Right Samples.everything
    it "decodes protobuf-es's bytes for everything, whose map entries aren't sorted, to the sample" do
      bytes <- fixture ProtobufEs "everything"
      decodeEverything bytes `shouldEqual` Right Samples.everything
    it "encodes everything to the bytes protobuf-es writes with the map entries in order" do
      bytes <- fixture ProtobufEs "everything-sorted"
      encodeEverything Samples.everything `shouldEqual` bytes
    it "encodes everything but the oneofs, which protoc-gen-go writes last, to protoc-gen-go's bytes" do
      bytes <- fixture ProtocGenGo "everything-without-oneofs"
      encodeEverything withoutOneofs `shouldEqual` bytes
    it "decodes protoc-gen-go's and protobuf-es's bytes for the proto2 sample" do
      go <- fixture ProtocGenGo "legacy"
      es <- fixture ProtobufEs "legacy"
      decodeLegacy go `shouldEqual` Right Samples.legacy
      decodeLegacy es `shouldEqual` Right Samples.legacy
    it "encodes the proto2 sample to protoc-gen-go's bytes" do
      bytes <- fixture ProtocGenGo "legacy"
      encodeLegacy Samples.legacy `shouldEqual` bytes

  describe "round trips" do
    it "decodes what it encodes, for every feature at once" do
      decodeEverything (encodeEverything Samples.everything) `shouldEqual` Right Samples.everything
    it "decodes what it encodes, for proto2" do
      decodeLegacy (encodeLegacy Samples.legacy) `shouldEqual` Right Samples.legacy
    it "encodes default proto3 messages to no bytes and decodes no bytes to them" do
      encodeEverything defaultEverything `shouldEqual` Bytes.empty
      encodeScalars defaultScalars `shouldEqual` Bytes.empty
      decodeScalars Bytes.empty `shouldEqual` Right defaultScalars
    it "keeps keywords and the generated code's own names apart" do
      let keywords = { type: 1, data: "d", input: true, end: 4, module: "m", value: 6, where: 7, loop: 8, position: 9 }
      decodeKeywords (encodeKeywords keywords) `shouldEqual` Right keywords
    it "nests a message that refers to itself as deep as it likes" do
      let deep = Array.foldl (\tree index -> Tree ((un Tree defaultTree) { label = show index, left = Just tree })) defaultTree (Array.range 1 200)
      decodeTree (encodeTree deep) `shouldEqual` Right deep

  describe "presence" do
    it "writes an optional field that's there, even with the default value" do
      encodeOptionals (defaultOptionals { maybeInt32 = Just 0 }) `shouldEqual` Bytes.fromArray [ 0x08, 0x00 ]
    it "leaves out an optional field that isn't there" do
      encodeOptionals defaultOptionals `shouldEqual` Bytes.empty
    it "writes a proto2 field that's there with its default, and always writes required fields" do
      encodeLegacy' (minimal { size = Just Small }) `shouldEqual` Bytes.fromArray [ 0x08, 0x00, 0x32, 0x00, 0x38, 0x00 ]
      encodeLegacy' minimal `shouldEqual` Bytes.fromArray [ 0x08, 0x00, 0x32, 0x00 ]

  describe "enums" do
    it "strips the prefix all values share" do
      map _.aDirection (decodeScalars (Bytes.fromArray [ 0x90, 0x01, 0x02 ])) `shouldEqual` Right EastByNortheast
    it "keeps numbers it doesn't know" do
      toColour 9 `shouldEqual` ColourUnrecognized 9
      fromColour (ColourUnrecognized 9) `shouldEqual` 9
      map _.aColour (decodeScalars (encodeScalars (defaultScalars { aColour = ColourUnrecognized 9 }))) `shouldEqual` Right (ColourUnrecognized 9)
    it "shows constructors" do
      show [ ColourBlue, ColourUnrecognized 9 ] `shouldEqual` "[ColourBlue,(ColourUnrecognized 9)]"
      show LightAmber `shouldEqual` "LightAmber"

  describe "repeated fields" do
    it "reads numbers packed or not, whichever way they were written" do
      let unpacked = Bytes.fromArray [ 0x18, 0x01, 0x18, 0x02 ]
      let packed = Bytes.fromArray [ 0x92, 0x01, 0x02, 0x03, 0x04 ]
      map _.int32s (decodeRepeateds unpacked) `shouldEqual` Right [ 1, 2 ]
      map _.unpackedInt32s (decodeRepeateds packed) `shouldEqual` Right [ 3, 4 ]
    it "packs numbers, booleans and enums, unless the field says not to" do
      encodeRepeateds (defaultRepeateds { int32s = [ 1, 2 ], unpackedInt32s = [ 3 ] })
        `shouldEqual` Bytes.fromArray [ 0x1a, 0x02, 0x01, 0x02, 0x90, 0x01, 0x03 ]
    it "reads packed fixed-width numbers" do
      let doubles = Bytes.fromArray [ 0x0a, 0x10, 0, 0, 0, 0, 0, 0, 0xf8, 0x3f, 0, 0, 0, 0, 0, 0, 0x04, 0xc0 ]
      map _.doubles (decodeRepeateds doubles) `shouldEqual` Right [ 1.5, -2.5 ]
    it "says where packed fixed-width numbers aren't whole" do
      decodeRepeateds (Bytes.fromArray [ 0x0a, 0x03, 0x00, 0x00, 0x00 ]) `shouldEqual` Left (Truncated 2)
    it "keeps unsigned numbers' bits" do
      map _.uint32s (decodeRepeateds (encodeRepeateds (defaultRepeateds { uint32s = [ UInt32 (-1) ] }))) `shouldEqual` Right [ UInt32 (-1) ]

  describe "maps" do
    it "lets a later entry for a key win" do
      let entries = Bytes.fromArray [ 0x0a, 0x05, 0x0a, 0x01, 0x61, 0x10, 0x01, 0x0a, 0x05, 0x0a, 0x01, 0x61, 0x10, 0x02 ]
      map _.byName (decodeMaps entries) `shouldEqual` Right (Map.fromFoldable [ "a" /\ 2 ])
    it "sorts unsigned keys as unsigned numbers" do
      Map.keys (Map.fromFoldable [ UInt64 (Int64.fromInt (-1)) /\ unit, UInt64 (Int64.fromInt 1) /\ unit ])
        `shouldEqual` Map.keys (Map.fromFoldable [ UInt64 (Int64.fromInt 1) /\ unit, UInt64 (Int64.fromInt (-1)) /\ unit ])
      Array.fromFoldable (Map.keys (Map.fromFoldable [ UInt32 (-1) /\ unit, UInt32 1 /\ unit ])) `shouldEqual` [ UInt32 1, UInt32 (-1) ]

  describe "oneof" do
    it "keeps the last of a oneof's fields" do
      let bytes = Bytes.fromArray [ 0x08, 0x05, 0x12, 0x01, 0x61 ]
      map _.pick (decodeChoice bytes) `shouldEqual` Right (Just (Variant.inj (Proxy :: _ "text") "a"))
    it "writes the one field that's there, at its number" do
      encodeChoice (defaultChoice { pick = Just (Variant.inj (Proxy :: _ "colour") ColourRed), after = "z" })
        `shouldEqual` Bytes.fromArray [ 0x20, 0x01, 0x2a, 0x01, 0x7a ]

  describe "messages decoded in a loop, as they are without fields_threshold" do
    it "reads a wide message's fields" do
      map _.aString (decodeWide (Bytes.fromArray [ 0x12, 0x01, 0x62, 0xf2, 0x01, 0x01, 0x63 ])) `shouldEqual` Right "b"
    it "says where a wide message's string isn't UTF-8" do
      decodeWide (Bytes.fromArray [ 0x08, 0x01, 0xf2, 0x01, 0x02, 0xc0, 0x80 ]) `shouldEqual` Left (InvalidUtf8 5)

  describe "messages decoded in two steps, with fields_threshold=1" do
    it "decodes protobuf-es's bytes for everything and encodes them back with the map entries in order" do
      bytes <- fixture ProtobufEs "everything"
      sorted <- fixture ProtobufEs "everything-sorted"
      map TwoStep.encodeEverything (TwoStep.decodeEverything bytes) `shouldEqual` Right sorted
    it "reads a wide message's fields" do
      map _.aString (TwoStep.decodeWide (Bytes.fromArray [ 0x12, 0x01, 0x62, 0xf2, 0x01, 0x01, 0x63 ])) `shouldEqual` Right "b"
    it "lets the last value of a field win" do
      map _.anInt32 (TwoStep.decodeWide (Bytes.fromArray [ 0x08, 0x01, 0x08, 0x02 ])) `shouldEqual` Right 2
    it "skips a field whose wire type isn't the one the message has for it" do
      map _.anInt32 (TwoStep.decodeWide (Bytes.fromArray [ 0x0a, 0x01, 0x61 ])) `shouldEqual` Right 0
    it "says where a wide message's string isn't UTF-8" do
      TwoStep.decodeWide (Bytes.fromArray [ 0x08, 0x01, 0xf2, 0x01, 0x02, 0xc0, 0x80 ]) `shouldEqual` Left (InvalidUtf8 5)
    it "says where a field runs past the end" do
      TwoStep.decodeWide (Bytes.fromArray [ 0x12, 0x05, 0x61 ]) `shouldEqual` Left (Truncated 1)
  where
  fixture writer name = readFile ("spec/fixtures/" <> name <> suffixOf writer) # liftEffect
  withoutOneofs = Samples.everything { choice = map (_ { pick = Nothing, other = Nothing }) Samples.everything.choice }
  minimal = { id: 0, name: Nothing, packedNumbers: [], numbers: [], next: Nothing, part: { on: Nothing }, size: Nothing }
  encodeLegacy' record = encodeLegacy (Legacy record)
