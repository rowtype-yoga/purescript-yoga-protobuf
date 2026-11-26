module Test.Yoga.Protobuf.WriterSpec where

import Prelude

import Data.Array as Array
import Data.Foldable (for_)
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Wire as Wire
import Yoga.Protobuf.Writer (encodeWith)
import Yoga.Protobuf.Writer as Writer

spec :: Spec Unit
spec = describe "Yoga.Protobuf.Writer" do
  describe "int32" do
    it "writes varints that varint32 reads back" do
      for_ [ 0, 1, 127, 128, 300, largestInt32, -1, smallestInt32 ] \number ->
        Wire.varint32 (encodeWith Writer.int32 number) 0 `shouldEqual` number
    it "writes a negative number in ten bytes" do
      Bytes.length (encodeWith Writer.int32 (-1)) `shouldEqual` 10
    it "writes 300 as AC 02" do
      encodeWith Writer.int32 300 `shouldEqual` Bytes.fromArray [ 0xac, 0x02 ]

  describe "uint32" do
    it "writes the bits of a negative Int in five bytes" do
      Bytes.length (encodeWith Writer.uint32 (-1)) `shouldEqual` 5

  describe "int64" do
    it "writes varints that varint64 reads back" do
      for_ int64s \number -> Wire.varint64 (encodeWith Writer.int64 number) 0 `shouldEqual` number

  describe "sint32 and sint64" do
    it "writes zigzag varints that sint32 reads back" do
      for_ [ 0, -1, 1, smallestInt32, largestInt32 ] \number ->
        Wire.sint32 (encodeWith Writer.sint32 number) 0 `shouldEqual` number
    it "writes -1 as 01" do
      encodeWith Writer.sint32 (-1) `shouldEqual` Bytes.fromArray [ 0x01 ]
    it "writes zigzag varints that sint64 reads back" do
      for_ int64s \number -> Wire.sint64 (encodeWith Writer.sint64 number) 0 `shouldEqual` number

  describe "fixed-width values" do
    it "writes fixed32 little-endian" do
      encodeWith Writer.fixed32 0x01020304 `shouldEqual` Bytes.fromArray [ 0x04, 0x03, 0x02, 0x01 ]
    it "writes fixed64 that fixed64 reads back" do
      for_ int64s \number -> Wire.fixed64 (encodeWith Writer.fixed64 number) 0 `shouldEqual` number
    it "writes a double that double reads back" do
      Wire.double (encodeWith Writer.double 3.14159) 0 `shouldEqual` 3.14159
    it "writes a float that float reads back" do
      Wire.float (encodeWith Writer.float 1.5) 0 `shouldEqual` 1.5

  describe "string" do
    it "writes the length, then the UTF-8" do
      encodeWith Writer.string "hé" `shouldEqual` Bytes.fromArray [ 0x03, 0x68, 0xc3, 0xa9 ]
    it "writes what string reads back, short and long" do
      for_ [ "", "alpha", "hé€𝄞", longText ] \text ->
        readString (encodeWith Writer.string text) `shouldEqual` text
    it "writes a lone surrogate as U+FFFD" do
      encodeWith Writer.string ("a" <> loneSurrogate) `shouldEqual` Bytes.fromArray [ 0x04, 0x61, 0xef, 0xbf, 0xbd ]

  describe "bytes" do
    it "writes the length, then the bytes" do
      encodeWith Writer.bytes (Bytes.fromArray [ 1, 2, 3 ]) `shouldEqual` Bytes.fromArray [ 3, 1, 2, 3 ]

  describe "lengthSince" do
    it "writes how much was written since the mark" do
      encodeWith nested "abc" `shouldEqual` Bytes.fromArray [ 0x2a, 0x05, 0x12, 0x03, 0x61, 0x62, 0x63 ]

  describe "encodeWith" do
    it "makes room for more than the first buffer holds" do
      Bytes.length (encodeWith (\writer count -> for_ (Array.range 1 count) \_ -> Writer.int32 writer 300) 3000)
        `shouldEqual` 6000
    it "writes the values back to front" do
      encodeWith (\writer numbers -> Writer.eachDescending numbers (Writer.int32 writer)) [ 1, 2, 3 ]
        `shouldEqual` Bytes.fromArray [ 1, 2, 3 ]
  where
  largestInt32 = 2147483647
  smallestInt32 = -2147483647 - 1
  loneSurrogate = Wire.invalidUtf8
  int64s =[ zero, one, negate one, Int64.fromInt 2147483647 * Int64.fromInt 4, bottom, top ] :: Array Int64
  longText = Array.foldMap (const "long text, é and 𝄞 ") (Array.range 1 200)
  nested writer text = do
    mark <- Writer.written writer
    Writer.string writer text
    Writer.tag writer 18
    Writer.lengthSince writer mark
    Writer.tag writer 42

readString :: Bytes -> String
readString input = do
  let end = Bytes.length input
  let start = Wire.varintEnd input 0 end
  Wire.string input start (Wire.delimitedEnd input 0 start end)
