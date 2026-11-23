// Writes bench/src/Bench/Wide.purs: bench.Wide's decoder and encoder in the shape the
// generator will emit, and the benchmark's sample. Fifty fields are too many to type by hand.
//
//   bun bench/tools/wide.ts

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

const defaultValue: Record<Kind, string> = {
  int32: "0",
  string: '""',
  double: "0.0",
  int64: "zero",
  bool: "false",
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

const names = fields.map((field) => field.name);

const loopWith = (replaced: string, value: string) =>
  `loop next ${names.map((name) => (name === replaced ? `(${value})` : name)).join(" ")}`;

const decodeCase = ({ number, name, kind }: (typeof fields)[number]) => {
  const tag = (number << 3) | wireType[kind];
  const lines = [`          ${tag} -> do`];
  if (kind === "string") {
    lines.push(
      `            let payload = Wire.varintEnd input afterTag end`,
      `            let next = Wire.delimitedEnd input afterTag payload end`,
      `            if next < 0 then Left (failure next afterTag)`,
      `            else do`,
      `              let text = Wire.string input payload next`,
      `              if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)`,
      `              else ${loopWith(name, "text").replace("(text)", "text")}`,
    );
    return lines.join("\n");
  }
  const read = { int32: "Wire.varint32", double: "Wire.double", int64: "Wire.varint64", bool: "Wire.bool" }[kind];
  const end = kind === "double" ? `Wire.fixedEnd afterTag 8 end` : `Wire.varintEnd input afterTag end`;
  lines.push(
    `            let next = ${end}`,
    `            if next < 0 then Left (failure next afterTag)`,
    `            else ${loopWith(name, `${read} input afterTag`)}`,
  );
  return lines.join("\n");
};

const unknownField = [
  `          tag -> do`,
  `            let next = Wire.skip input tag afterTag end`,
  `            if next < 0 then Left (failure next afterTag)`,
  `            else loop next ${names.join(" ")}`,
].join("\n");

// purs-backend-es turns a case on an Int into a chain of ifs, so with many fields the generator
// splits the fields into groups of at most eight by tag and finds the group by bisection.
const groupSize = 8;

const dispatch = (group: typeof fields, indent: string): string => {
  if (group.length <= groupSize) {
    const cases = group.map(decodeCase).join("\n") + "\n" + unknownField;
    return `${indent}case tag of\n${cases.replace(/^ {10}/gm, indent + "  ")}`;
  }
  const half = Math.ceil(group.length / groupSize / 2) * groupSize;
  const firstTag = (field: (typeof fields)[number]) => field.number << 3;
  return [
    `${indent}if tag < ${firstTag(group[half])} then`,
    dispatch(group.slice(0, half), indent + "  "),
    `${indent}else`,
    dispatch(group.slice(half), indent + "  "),
  ].join("\n");
};

const writeField =({ number, name, kind }: (typeof fields)[number]) => {
  const tag = (number << 3) | wireType[kind];
  const condition = {
    int32: `wide.${name} /= 0`,
    string: `wide.${name} /= ""`,
    double: `wide.${name} /= 0.0`,
    int64: `wide.${name} /= zero`,
    bool: `wide.${name}`,
  }[kind];
  const write = { int32: "int32", string: "string", double: "double", int64: "int64", bool: "bool" }[kind];
  return [
    `  when (${condition}) do`,
    `    Writer.${write} writer wide.${name}`,
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

wideFrom :: Bytes -> Int -> Int -> Either DecodeError Wide
wideFrom input start end = loop start ${fields.map(({ kind }) => defaultValue[kind]).join(" ")}
  where
  loop position ${names.join(" ")}
    | position >= end = Right { ${names.join(", ")} }
    | otherwise = do
        let afterTag = Wire.varintEnd input position end
        let tag = Wire.varint32 input position
        if afterTag < 0 then Left (failure afterTag position)
        else
${dispatch(fields, "          ")}

writeWide :: Writer -> Wide -> Effect Unit
writeWide writer wide = do
${fields.slice().reverse().map(writeField).join("\n")}
`;

await Bun.write(new URL("../src/Bench/Wide.purs", import.meta.url), source);
