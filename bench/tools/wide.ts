// Writes bench/src/Bench/Wide.purs: bench.Wide's decoder and encoder in the shape the
// generator will emit, and the benchmark's sample. Fifty fields are too many to type by hand.
//
//   bun bench/tools/wide.ts
//
// A message with this many fields is decoded in two steps. Carrying fifty fields from one step of
// a loop to the next costs every step on both backends, so the decoder's loop only notes where
// each field is (Yoga.Protobuf.Fields), and then the record is read from those places.

const fieldCount = 50;

type Kind = "int32" | "string" | "double" | "int64" | "bool";

const kindOf = (number: number): Kind =>
  (["bool", "int32", "string", "double", "int64"] as const)[number % 5];

const fields = Array.from({ length: fieldCount }, (_, index) => {
  const number = index + 1;
  return { number, name: `f${number}`, kind: kindOf(number) };
});

const purescriptType: Record<Kind, string> = {
  int32: "Int",
  string: "String",
  double: "Number",
  int64: "Int64",
  bool: "Boolean",
};

const wireType: Record<Kind, number> = { int32: 0, string: 2, double: 1, int64: 0, bool: 0 };

const sampleValue = (number: number, kind: Kind): string => {
  switch (kind) {
    case "int32":
      return `${number * 1000 + 7}`;
    case "string":
      return `"field ${number}"`;
    case "double":
      return `${number}.25`;
    case "int64":
      return `Int64.fromInt ${number} * Int64.fromInt 100000 * Int64.fromInt 100000`;
    case "bool":
      return "true";
  }
};

// The wire type each field number has, -1 for numbers the message doesn't have.
const wireTypes = [-1, ...fields.map(({ kind }) => wireType[kind])];

const readField = ({ number, name, kind }: (typeof fields)[number]) =>
  kind === "string"
    ? `${name}: runFn4 Fields.string input fields ${number} end`
    : `${name}: runFn3 Fields.${kind} input fields ${number}`;

const strings = fields.filter(({ kind }) => kind === "string");

const utf8Check = ({ number, name }: (typeof fields)[number]) =>
  `      else if wide.${name} == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields ${number} end))`;

const writeField = ({ number, name, kind }: (typeof fields)[number]) => {
  const tag = (number << 3) | wireType[kind];
  const condition = {
    int32: `wide.${name} /= 0`,
    string: `wide.${name} /= ""`,
    double: `wide.${name} /= 0.0`,
    int64: `wide.${name} /= zero`,
    bool: `wide.${name}`,
  }[kind];
  return [
    `  when (${condition}) do`,
    `    Writer.${kind} writer wide.${name}`,
    `    Writer.tag writer ${tag}`,
  ].join("\n");
};

const source = `-- | \`bench.Wide\`, in the shape the generator will emit. Written by bench/tools/wide.ts.
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
  { ${fields.map(({ name, kind }) => `${name} :: ${purescriptType[kind]}`).join("\n  , ")}
  }

decodeWide :: Bytes -> Either DecodeError Wide
decodeWide input = decodeMessage wideFrom input

encodeWide :: Wide -> Bytes
encodeWide wide = encodeWith writeWide wide

sample :: Wide
sample =
  { ${fields.map(({ number, name, kind }) => `${name}: ${sampleValue(number, kind)}`).join("\n  , ")}
  }

wideFrom :: Reader Wide
wideFrom = mkFn3 \\input start end -> do
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
  case scan start (Fields.new input ${fieldCount + 1}) of
    Left error -> Left error
    Right fields -> do
      let
        wide =
          { ${fields.map(readField).join("\n          , ")}
          }
      if false then Left (InvalidUtf8 0)
${strings.map(utf8Check).join("\n")}
      else Right wide

wireTypes :: Array Int
wireTypes = [ ${wireTypes.join(", ")} ]

writeWide :: Writer -> Wide -> Effect Unit
writeWide writer wide = do
${fields.slice().reverse().map(writeField).join("\n")}
`;

await Bun.write(new URL("../src/Bench/Wide.purs", import.meta.url), source);
