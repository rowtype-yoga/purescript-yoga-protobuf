// The JavaScript comparators: protobuf-es and protobufjs's static code, on the same samples as
// the PureScript benchmark, measured the same way. Prints
// `RESULT <implementation> <message> <encode|decode> <ns/op> <allocs/op>`.
//
//   bun bench.mjs

import { create, fromBinary, toBinary } from "@bufbuild/protobuf";
import { InnerSchema, MsgSchema, RepeatedNestedSchema, WideSchema } from "./gen/bench_pb.js";
import { bench as pbjs } from "./gen/bench_pbjs.js";

const iterations = { nested: 200_000, "repeated-nested": 2_000, wide: 200_000 };

let sunk = 0;

const measure = (implementation, name, operation, run) => {
  const count = iterations[name];
  for (let index = 0; index < count / 10; index++) run();
  const started = performance.now();
  for (let index = 0; index < count; index++) run();
  const elapsed = performance.now() - started;
  console.log(`RESULT ${implementation} ${name} ${operation} ${(elapsed * 1e6) / count} 0`);
};

const nestedFields = () => ({
  id: 12345,
  name: "hello world, this is a name",
  nums: Array.from({ length: 20 }, (_, index) => index + 1),
  inner: { a: 7, b: "inner string" },
  tags: Object.fromEntries(Array.from({ length: 5 }, (_, index) => [`key${index + 1}`, (index + 1) * 100])),
  score: 3.14159,
  ok: true,
  labels: ["alpha", "beta", "gamma"],
});

const repeatedNestedFields = () => ({
  items: Array.from({ length: 1000 }, (_, index) => ({ a: index, b: `item ${index}` })),
});

// Field n by its kind: int32 n*1000+7, string "field n", double n.25, int64 n*10^10, bool true.
const wideFields = (int64) =>
  Object.fromEntries(
    Array.from({ length: 50 }, (_, index) => {
      const number = index + 1;
      const value = [true, number * 1000 + 7, `field ${number}`, number + 0.25, int64(number * 10_000_000_000)][number % 5];
      return [`f${number}`, value];
    }),
  );

const readNested = (message) => message.id;
const readRepeatedNested = (message) => message.items.length;
const readWide = (message) => message.f2.length + Math.floor(message.f23) + Number(BigInt.asIntN(32, BigInt(message.f49)));

const protobufEs = {
  nested: [MsgSchema, create(MsgSchema, { ...nestedFields(), big: 1234567890123n }), readNested],
  "repeated-nested": [RepeatedNestedSchema, create(RepeatedNestedSchema, repeatedNestedFields()), readRepeatedNested],
  wide: [WideSchema, create(WideSchema, wideFields(BigInt)), readWide],
};

for (const [name, [schema, sample, read]] of Object.entries(protobufEs)) {
  const encoded = toBinary(schema, sample);
  measure("protobuf-es", name, "encode", () => {
    sunk += toBinary(schema, sample).length;
  });
  measure("protobuf-es", name, "decode", () => {
    sunk += read(fromBinary(schema, encoded));
  });
}

const protobufjs = {
  nested: [pbjs.Msg, pbjs.Msg.create({ ...nestedFields(), big: 1234567890123 }), readNested],
  "repeated-nested": [pbjs.RepeatedNested, pbjs.RepeatedNested.create(repeatedNestedFields()), readRepeatedNested],
  wide: [pbjs.Wide, pbjs.Wide.create(wideFields((value) => value)), (message) => message.f2.length + Math.floor(message.f23) + message.f49.low],
};

for (const [name, [type, sample, read]] of Object.entries(protobufjs)) {
  const encoded = type.encode(sample).finish();
  measure("protobufjs", name, "encode", () => {
    sunk += type.encode(sample).finish().length;
  });
  measure("protobufjs", name, "decode", () => {
    sunk += read(type.decode(encoded));
  });
}

if (sunk === 42) console.log("");
