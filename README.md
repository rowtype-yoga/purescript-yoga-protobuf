# purescript-yoga-protobuf

Fast protocol buffers for PureScript. The same code runs on JavaScript and, compiled with
[Iris](https://github.com/i-am-the-slime/purescript-analyzer/tree/iris-go), as native Go.

Messages are plain records, decoding gives you an `Either DecodeError`, and broken input is a
`Left`, never an exception: truncated bytes, overlong varints, bad wire types and text that isn't
UTF-8 all say where they went wrong.

```purescript
decodeMsg :: Bytes -> Either DecodeError Msg
encodeMsg :: Msg -> Bytes
```

## Status

Milestone 1 of the plan: the runtime (`Yoga.Protobuf.*`) and hand-written codecs for the
benchmark's messages, in the shape the code generator will emit. There's no generator yet, so
you can't point it at your `.proto` files. proto3 only for now.

What's in the runtime:

- **`Wire`** reads varints, fixed-width numbers, strings and bytes, checking bounds and UTF-8
- **`Writer`** writes back to front, so a nested message needs no size pass
- **`Repeated`** collects repeated fields in place while decoding (an array push on JavaScript,
  `append` on Go)
- **`Decode`** has what generated decoders share, like building a `Map` from map entries
- **`Fields`** lets a decoder for a message with many fields note where each one is first and
  read the record afterwards
- **`Error`**, **`Codec`** and **`Bytes`** (a `Uint8Array` on JavaScript, a `[]byte` on Go)

`int64` fields are `Int64` from `int64`, which Iris turns into Go's `int64`. Maps are `Data.Map`.

## Benchmarks

Three messages from [bench/proto/bench.proto](bench/proto/bench.proto):

- **nested**: a bit of everything in 164 bytes: numbers, an `int64`, strings, a packed field, a
  nested message, a map, repeated strings
- **repeated-nested**: 1,000 small nested messages
- **wide**: 50 fields of which the program reads three

Median of three runs on an Apple M5 Max. Go 1.27, Bun 1.2.21, Iris 0.1.17-go.1.

| Go (ns/op · allocs/op) | nested encode | nested decode | repeated-nested encode | repeated-nested decode | wide encode | wide decode |
| --- | --- | --- | --- | --- | --- | --- |
| yoga-protobuf (Iris) | 145 ns · 1 | 398 ns · 22 | 12,209 ns · 1 | 22,933 ns · 1011 | 254 ns · 1 | 415 ns · 11 |
| protoc-gen-go | 614 ns · 21 | 704 ns · 36 | 23,504 ns · 1 | 44,013 ns · 2012 | 355 ns · 1 | 388 ns · 11 |
| vtprotobuf | 174 ns · 1 | 298 ns · 18 | 6,363 ns · 1 | 21,359 ns · 2012 | 101 ns · 1 | 231 ns · 11 |
| hyperpb | – | 242 ns · 2 | – | 16,726 ns · 1 | – | 318 ns · 2 |
| hyperpb (profile-guided) | – | 238 ns · 2 | – | 15,503 ns · 1 | – | 319 ns · 2 |

| Bun (ns/op) | nested encode | nested decode | repeated-nested encode | repeated-nested decode | wide encode | wide decode |
| --- | --- | --- | --- | --- | --- | --- |
| yoga-protobuf | 585 ns | 805 ns | 39,772 ns | 41,509 ns | 896 ns | 947 ns |
| protobuf-es | 605 ns | 998 ns | 49,484 ns | 89,668 ns | 1,470 ns | 1,347 ns |
| protobufjs (static) | 680 ns | 507 ns | 57,747 ns | 32,697 ns | 1,090 ns | 628 ns |

hyperpb only decodes, into an arena it reuses. vtprotobuf doesn't check UTF-8 when it encodes;
protoc-gen-go and this library do. For scale: the existing `protobuf` package took about 150 µs
for an encode plus a decode of the nested message.

Still behind: vtprotobuf on encoding anything big or wide, protoc-gen-go and vtprotobuf on
decoding the wide message on Go, and protobufjs on decoding on Bun.

### Running them

You need Go, Bun, `protoc`, `spago`, `purs-backend-es` and `iris` on your `PATH`.

```
bench/run.sh
```

It builds everything, runs each implementation three times (`RUNS=5 bench/run.sh` for more),
prints the tables above and keeps the raw numbers in `bench/results`. Before measuring, the
PureScript program checks that it reads what protoc-gen-go wrote for each sample and writes exactly
those bytes back.

## Tests

The specs are a program, so they run on both backends:

```
spago build -p yoga-protobuf-test
bun -e "import('./output-es/Test.Main/index.js').then(spec => spec.main())"
iris run --go -p yoga-protobuf-test --main Test.Main
```
