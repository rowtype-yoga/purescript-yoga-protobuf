// Writes the features samples as protobuf-es encodes them, to spec/fixtures/<name>.es.bin, for the
// specs that check the generated codecs against another implementation. The samples are the ones
// in spec/src/Test/Features/Samples.purs and spec/fixtures/go/main.go. Map entries go in an order
// that isn't sorted, on purpose.
//
//   bun fixtures.mjs

import { create, toBinary } from "@bufbuild/protobuf";
import { EverythingSchema, MapsSchema } from "./gen/features_pb.js";
import { LegacySchema } from "./gen/legacy_pb.js";

const RED = 1;
const GREEN = 2;
const BLUE = 3;

const everything = create(EverythingSchema, {
  scalars: {
    aDouble: 1.5,
    aFloat: 2.25,
    anInt32: -42,
    anInt64: -9000000000n,
    aUint32: 4000000000,
    aUint64: 18000000000000000000n,
    aSint32: -7,
    aSint64: -123456789012n,
    aFixed32: 3000000000,
    aFixed64: 12345678901234n,
    anSfixed32: -5,
    anSfixed64: -6000000000n,
    aBool: true,
    aString: "héllo ☃",
    someBytes: new Uint8Array([0, 1, 2, 255]),
    aColour: BLUE,
    aLight: 2,
    aDirection: 2,
  },
  optionals: {
    maybeInt32: 0,
    maybeString: "",
    maybeColour: RED,
    maybeUint64: 7n,
    maybeBool: false,
  },
  repeateds: {
    doubles: [1.5, -2.5],
    floats: [0.5],
    int32s: [1, -1, 300],
    int64s: [-1n, 5000000000n],
    uint32s: [1, 4000000000],
    uint64s: [1n],
    sint32s: [-1, 1],
    sint64s: [-2n],
    fixed32s: [1, 2],
    fixed64s: [3n],
    sfixed32s: [-4],
    sfixed64s: [-5n],
    bools: [true, false, true],
    strings: ["a", "", "ü"],
    byteStrings: [new Uint8Array([1]), new Uint8Array([])],
    colours: [RED, BLUE, 7],
    messages: [{ anInt32: 1 }, {}],
    unpackedInt32s: [1, 2],
    unpackedDoubles: [0.25],
    unpackedColours: [GREEN],
  },
  maps: {
    byName: { zero: 0, two: 2, one: 1 },
    messages: { 3: {}, 1: { aString: "x" } },
    colours: { 4000000000: BLUE, 1: RED },
    byInt64: { 5000000000: "big", "-5": "minus five" },
    byBool: { true: new Uint8Array([9]), false: new Uint8Array([]) },
    bySint32: { "-3": 0.5 },
    things: { 2: { name: "two", mood: 1 } },
  },
  choice: {
    pick: { case: "scalars", value: { aBool: true } },
    after: "after",
    other: { case: "blob", value: new Uint8Array([7, 8]) },
  },
  tree: {
    label: "root",
    left: { label: "l" },
    children: [{ label: "c1" }, { label: "c2", left: { label: "c2l" } }],
    named: { n: { label: "named" } },
  },
  outer: {
    inner: { kind: 1, value: 5 },
    inners: [{ kind: 2 }, {}],
    kind: 2,
  },
  keywords: { type: 1, data: "d", input: true, end: 4, module: "m", value: 6, where: 7, loop: 8, position: 9 },
  uses: {
    thing: { name: "thing", mood: 2 },
    mood: 1,
    things: [{ name: "a" }],
    empty: {},
  },
  wide: {
    anInt32: 1,
    aString: "two",
    aDouble: 3.5,
    anInt64: 4n,
    aBool: true,
    aUint32: 4000000000,
    aSint32: -7,
    aSint64: -8n,
    aFixed32: 9,
    aFixed64: 10n,
    anSfixed32: -11,
    anSfixed64: -12n,
    aFloat: 13.5,
    someBytes: new Uint8Array([14]),
    aColour: GREEN,
    aUint64: 16n,
    anotherInt32: 17,
    anotherString: "eighteen",
    anotherDouble: 19.5,
    anotherInt64: 20n,
    anotherBool: true,
    lastString: "thirty",
  },
  empty: {},
});

const legacy = create(LegacySchema, {
  id: 1,
  packedNumbers: [1, 2, 3],
  numbers: [4, 5],
  next: { id: 2, name: "second", part: {} },
  part: { on: true },
  size: 1,
});

const write = (name, bytes) => Bun.write(new URL(`../${name}.es.bin`, import.meta.url), bytes);

await write("everything", toBinary(EverythingSchema, everything));

// The same with the map entries in the order of their keys, which is how this library writes
// them: protobuf-es then writes the same bytes. (A JavaScript object keeps keys that are array
// indexes in ascending order, and the others in the order they were added.)
const sorted = create(EverythingSchema, everything);
sorted.maps = create(MapsSchema, {
  ...everything.maps,
  byName: { one: 1, two: 2, zero: 0 },
  byInt64: { "-5": "minus five", 5000000000: "big" },
  byBool: { false: new Uint8Array([]), true: new Uint8Array([9]) },
});
await write("everything-sorted", toBinary(EverythingSchema, sorted));
await write("legacy", toBinary(LegacySchema, legacy));
