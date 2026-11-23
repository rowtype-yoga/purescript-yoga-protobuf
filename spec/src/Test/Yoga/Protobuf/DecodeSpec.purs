module Test.Yoga.Protobuf.DecodeSpec where

import Prelude

import Data.Array as Array
import Data.Map as Map
import Data.Tuple.Nested ((/\))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Decode (mapFromEntries, packedInt32)
import Yoga.Protobuf.Error (DecodeError(..), failure)
import Yoga.Protobuf.Repeated as Repeated

spec :: Spec Unit
spec = describe "Yoga.Protobuf.Decode" do
  describe "mapFromEntries" do
    it "builds the map of sorted entries" do
      mapFromEntries (repeatedOf (entries [ "a", "b", "c", "d", "e", "f", "g" ]))
        `shouldEqual` Map.fromFoldable (map (\key -> key /\ key) [ "a", "b", "c", "d", "e", "f", "g" ])
    it "builds the map of unsorted entries" do
      mapFromEntries (repeatedOf (entries [ "c", "a", "b" ]))
        `shouldEqual` Map.fromFoldable (map (\key -> key /\ key) [ "a", "b", "c" ])
    it "keeps the last entry for a key" do
      mapFromEntries (repeatedOf [ { key: 1, value: "first" }, { key: 1, value: "last" } ])
        `shouldEqual` Map.singleton 1 "last"
    it "builds a map that lookups work on" do
      Map.lookup "f" (mapFromEntries (repeatedOf (entries [ "a", "b", "c", "d", "e", "f", "g" ])))
        `shouldEqual` pure "f"

  describe "packedInt32" do
    it "adds the packed varints to what's there" do
      Repeated.freeze (packedInt32 (Bytes.fromArray [ 0x03, 0xac, 0x02 ]) 0 3 (Repeated.snoc Repeated.empty 1))
        `shouldEqual` [ 1, 3, 300 ]

  describe "Repeated" do
    it "starts each builder empty, however many were built before" do
      Repeated.freeze (Repeated.snoc Repeated.empty 1) `shouldEqual` [ 1 ]
      Repeated.freeze (Repeated.empty :: Repeated.Repeated Int) `shouldEqual` []

  describe "failure" do
    it "names the error each code stands for" do
      map (\code -> failure code 7) [ -1, -2, -3, -4 ]
        `shouldEqual` [ Truncated 7, MalformedVarint 7, InvalidWireType 7, InvalidUtf8 7 ]
  where
  entries keys = map (\key -> { key, value: key }) keys

repeatedOf :: forall a. Array a -> Repeated.Repeated a
repeatedOf values = Array.foldl Repeated.snoc Repeated.empty values
