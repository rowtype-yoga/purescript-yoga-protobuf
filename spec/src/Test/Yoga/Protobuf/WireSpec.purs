module Test.Yoga.Protobuf.WireSpec where

import Prelude

import Data.Array as Array
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Wire as Wire

spec :: Spec Unit
spec = describe "Yoga.Protobuf.Wire" do
  describe "varintEnd" do
    it "ends a one-byte varint after its byte" do
      endOf [ 0x01 ] `shouldEqual` 1
    it "ends a varint after the first byte below 0x80" do
      endOf [ 0xac, 0x02, 0x07 ] `shouldEqual` 2
    it "says -1 when the input ends inside the varint" do
      endOf [ 0x80, 0x80 ] `shouldEqual` -1
    it "says -1 for no input at all" do
      endOf [] `shouldEqual` -1
    it "says -2 for a varint longer than ten bytes" do
      endOf (Array.replicate 10 0x80 <> [ 0x01 ]) `shouldEqual` -2
    it "stops at the end it's given, not at the end of the bytes" do
      Wire.varintEnd (Bytes.fromArray [ 0x80, 0x01 ]) 0 1 `shouldEqual` -1

  describe "varint32" do
    it "reads a two-byte varint" do
      Wire.varint32 (Bytes.fromArray [ 0xac, 0x02 ]) 0 `shouldEqual` 300
    it "reads the ten-byte encoding of -1 as -1" do
      Wire.varint32 (Bytes.fromArray (Array.replicate 9 0xff <> [ 0x01 ])) 0 `shouldEqual` -1
    it "keeps the lowest 32 bits of a longer varint" do
      Wire.varint32 (Bytes.fromArray [ 0x81, 0x80, 0x80, 0x80, 0x10 ]) 0 `shouldEqual` 1

  describe "delimitedEnd" do
    it "ends the payload after its length" do
      delimitedEndOf [ 0x03, 0x61, 0x62, 0x63 ] `shouldEqual` 4
    it "says -1 when the payload is longer than the input" do
      delimitedEndOf [ 0x05, 0x61 ] `shouldEqual` -1
    it "passes on a broken length varint" do
      delimitedEndOf [ 0x80 ] `shouldEqual` -1

  describe "skip" do
    it "skips a varint field" do
      skipOf [ 0x08, 0x96, 0x01, 0x10 ] `shouldEqual` 3
    it "skips a fixed64 field" do
      skipOf ([ 0x09 ] <> Array.replicate 8 0) `shouldEqual` 9
    it "skips a length-delimited field" do
      skipOf [ 0x12, 0x02, 0x61, 0x62 ] `shouldEqual` 4
    it "skips a group up to its matching end, past groups inside it" do
      skipOf [ 0x0b, 0x13, 0x10, 0x01, 0x14, 0x0c, 0x08 ] `shouldEqual` 6
    it "says -3 for a group ended by another field's end" do
      skipOf [ 0x0b, 0x14 ] `shouldEqual` -3
    it "says -3 for field number 0" do
      skipOf [ 0x00, 0x01 ] `shouldEqual` -3
    it "says -3 for wire type 6" do
      skipOf [ 0x0e, 0x01 ] `shouldEqual` -3
    it "says -1 for a truncated fixed32" do
      skipOf [ 0x0d, 0x01, 0x02 ] `shouldEqual` -1

  describe "string" do
    it "reads ASCII" do
      stringOf [ 0x68, 0x69 ] `shouldEqual` "hi"
    it "reads two-, three- and four-byte characters" do
      stringOf [ 0x68, 0xc3, 0xa9, 0xe2, 0x82, 0xac, 0xf0, 0x9d, 0x84, 0x9e ] `shouldEqual` "hé€𝄞"
    it "reads a string longer than the hand-decoded ones" do
      stringOf (Array.replicate 40 0x61 <> [ 0xc3, 0xa9 ]) `shouldEqual` (power "a" 40 <> "é")
    it "rejects an overlong encoding" do
      stringOf [ 0xc0, 0x80 ] `shouldEqual` Wire.invalidUtf8
    it "rejects an encoded surrogate" do
      stringOf [ 0xed, 0xa0, 0x80 ] `shouldEqual` Wire.invalidUtf8
    it "rejects a sequence cut short" do
      stringOf [ 0x61, 0xe2, 0x82 ] `shouldEqual` Wire.invalidUtf8
    it "rejects a byte that never starts a character" do
      stringOf [ 0xff ] `shouldEqual` Wire.invalidUtf8
    it "rejects code points past U+10FFFF" do
      stringOf [ 0xf4, 0x90, 0x80, 0x80 ] `shouldEqual` Wire.invalidUtf8
    it "rejects invalid UTF-8 in a long string too" do
      stringOf (Array.replicate 40 0x61 <> [ 0xc0, 0x80 ]) `shouldEqual` Wire.invalidUtf8

  describe "utf8Valid" do
    it "accepts what string reads" do
      utf8ValidOf [ 0x68, 0xc3, 0xa9, 0xf0, 0x9d, 0x84, 0x9e ] `shouldEqual` true
    it "rejects what string rejects" do
      utf8ValidOf [ 0xed, 0xa0, 0x80 ] `shouldEqual` false

  describe "packedVarintsValid" do
    it "accepts whole varints" do
      packedValidOf [ 0x01, 0xac, 0x02, 0x7f ] `shouldEqual` true
    it "rejects a cut-off last varint" do
      packedValidOf [ 0x01, 0xac ] `shouldEqual` false

  describe "varintCount" do
    it "counts the varints in a packed field" do
      Wire.varintCount (bytesOf [ 0x01, 0xac, 0x02, 0x7f ]) 0 4 `shouldEqual` 3

  describe "fixed-width values" do
    it "reads fixed32 bits" do
      Wire.fixed32 (bytesOf [ 0xff, 0xff, 0xff, 0xff ]) 0 `shouldEqual` -1
    it "reads a double" do
      Wire.double (bytesOf [ 0x6e, 0x86, 0x1b, 0xf0, 0xf9, 0x21, 0x09, 0x40 ]) 0 `shouldEqual` 3.14159
    it "reads a float" do
      Wire.float (bytesOf [ 0x00, 0x00, 0xc0, 0x3f ]) 0 `shouldEqual` 1.5

  describe "zigzag" do
    it "maps 1 to -1 and 4294967294 to 2147483647" do
      map Wire.zigzag32 [ 0, 1, 2, -2, -1 ] `shouldEqual` [ 0, -1, 1, top, bottom ]
  where
  endOf numbers = Wire.varintEnd (bytesOf numbers) 0 (Array.length numbers)
  delimitedEndOf numbers = do
    let input = bytesOf numbers
    let end = Array.length numbers
    Wire.delimitedEnd input 0 (Wire.varintEnd input 0 end) end
  skipOf numbers = do
    let input = bytesOf numbers
    let end = Array.length numbers
    Wire.skip input (Wire.varint32 input 0) (Wire.varintEnd input 0 end) end
  stringOf numbers = Wire.string (bytesOf numbers) 0 (Array.length numbers)
  utf8ValidOf numbers = Wire.utf8Valid (bytesOf numbers) 0 (Array.length numbers)
  packedValidOf numbers = Wire.packedVarintsValid (bytesOf numbers) 0 (Array.length numbers)
  power text count = Array.foldMap (const text) (Array.replicate count unit)

bytesOf :: Array Int -> Bytes
bytesOf = Bytes.fromArray
