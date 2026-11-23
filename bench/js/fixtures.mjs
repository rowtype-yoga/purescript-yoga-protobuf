// Writes the samples as protobuf-es encodes them to bench/fixtures/<name>.es.bin, for the specs
// that check the hand-written decoders read other implementations' bytes.
//
//   bun fixtures.mjs

import { create, toBinary } from "@bufbuild/protobuf";
import { MsgSchema, RepeatedNestedSchema, WideSchema } from "./gen/bench_pb.js";

const nested = create(MsgSchema, {
  id: 12345,
  big: 1234567890123n,
  name: "hello world, this is a name",
  nums: Array.from({ length: 20 }, (_, index) => index + 1),
  inner: { a: 7, b: "inner string" },
  // Unsorted on purpose: the decoder must not rely on the order of map entries.
  tags: Object.fromEntries([3, 1, 5, 2, 4].map((index) => [`key${index}`, index * 100])),
  score: 3.14159,
  ok: true,
  labels: ["alpha", "beta", "gamma"],
});

const repeatedNested = create(RepeatedNestedSchema, {
  items: Array.from({ length: 1000 }, (_, index) => ({ a: index, b: `item ${index}` })),
});

const wide = create(
  WideSchema,
  Object.fromEntries(
    Array.from({ length: 50 }, (_, index) => {
      const number = index + 1;
      const value = [true, number * 1000 + 7, `field ${number}`, number + 0.25, BigInt(number) * 10_000_000_000n][number % 5];
      return [`f${number}`, value];
    }),
  ),
);

const write = (name, bytes) => Bun.write(new URL(`../fixtures/${name}.es.bin`, import.meta.url), bytes);

await write("nested", toBinary(MsgSchema, nested));
await write("repeated-nested", toBinary(RepeatedNestedSchema, repeatedNested));
await write("wide", toBinary(WideSchema, wide));
