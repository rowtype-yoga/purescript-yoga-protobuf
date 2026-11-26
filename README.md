# purescript-yoga-protobuf

Fast protocol buffers for PureScript. The same code runs on JavaScript and, compiled with
[Iris](https://github.com/i-am-the-slime/iris-go-backend), as native Go.

You point `protoc` at your `.proto` files and get a PureScript module per file. Messages are plain
records, decoding gives you an `Either DecodeError`, and broken input is a `Left`, never an
exception: truncated bytes, overlong varints, bad wire types and text that isn't UTF-8 all say where
they went wrong.

```purescript
decodeMsg :: Bytes -> Either DecodeError Msg
encodeMsg :: Msg -> Bytes
```

[examples/order-report](examples/order-report) is a whole program: a million orders from a
`.proto`, decoded, filtered, totalled and encoded again, next to the same program with
protoc-gen-go. It decodes 1.5× and encodes 2.3× faster, and writes the same bytes.

## Status

Milestone 2: the code generator, `protoc-gen-purescript`. It's written in PureScript too, runs as
a native binary (Iris) or on Bun, and generates its own `descriptor.proto` and `plugin.proto`
decoders. proto3 and proto2 work; editions, groups and extensions don't yet.

## Installing

It's not on the registry yet, so grab it from GitHub in your `spago.yaml`:

```yaml
workspace:
  extraPackages:
    yoga-protobuf:
      git: https://github.com/rowtype-yoga/purescript-yoga-protobuf.git
      ref: v0.2.0
```

That's all you need on JavaScript. On Go you need googoo 0.1.18-go.5 or newer
(`brew install spago i-am-the-slime/tap/iris`) and Go 1.27.

## Generating code

You need `protoc`, and either Iris and Go 1.27 for the native plugin
(`brew install spago i-am-the-slime/tap/iris`) or Bun for the other one.

```
iris go -p protoc-gen-purescript --entry Yoga.Protobuf.Plugin.Native.main
protoc --plugin=protoc-gen-purescript=bin/protoc-gen-purescript --purescript_out=src foo.proto
```

`bin/protoc-gen-purescript` runs the native binary. For Bun, `spago build -p yoga-protobuf-plugin`
and use `bin/protoc-gen-purescript-bun` instead. Both write exactly the same code.

`foo.proto` in package `my.app` becomes `src/Yoga/Protobuf/Generated/My/App/Foo.purs`. Options go
before the output directory, separated by commas:

```
protoc --purescript_out=module_prefix=MyApp.Proto,fields_threshold=10:src foo.proto
```

- `module_prefix` puts the modules somewhere else than under `Yoga.Protobuf.Generated`
- `fields_threshold` decodes messages with at least that many plain fields in two steps (off by
  default, see below)

The generated code needs these packages in your `spago.yaml`: `yoga-protobuf`, `prelude`, `effect`,
`either`, `functions`, `int64`, `maybe`, `newtype`, `ordered-collections` and `variant`.

## What you get

For this:

```proto
message Person {
  string name = 1;
  optional int32 age = 2;
  repeated Pet pets = 3;
  map<string, string> labels = 4;
  oneof contact {
    string email = 5;
    string phone = 6;
  }
}

enum Pet {
  PET_UNSPECIFIED = 0;
  PET_DOG = 1;
  PET_CAT = 2;
}
```

you get

```purescript
type Person =
  { name :: String
  , age :: Maybe Int
  , pets :: Array Pet
  , labels :: Map String String
  , contact :: Maybe (Variant (email :: String, phone :: String))
  }

data Pet = Unspecified | Dog | Cat | PetUnrecognized Int

defaultPerson :: Person
decodePerson :: Bytes -> Either DecodeError Person
encodePerson :: Person -> Bytes
personCodec :: Codec Person
toPet :: Int -> Pet
fromPet :: Pet -> Int
```

- every scalar type: `int32`, `sint32` and `sfixed32` are `Int`, `uint32` and `fixed32` are
  `UInt32`, the 64-bit ones `Int64` or `UInt64`, `float` and `double` `Number`, `bytes` are
  `Yoga.Protobuf.Bytes`
- explicit presence (`optional`, message fields, proto2 fields) is a `Maybe`; proto2 `required`
  fields aren't
- `repeated` fields are arrays. Numbers, booleans and enums are packed when they should be, and
  read either way
- maps are `Data.Map`
- a `oneof` is a `Maybe` of a `Variant` of its fields
- enums are open: numbers the enum doesn't have are kept in `…Unrecognized`. If all values start
  with the enum's name (`PET_`), that's left off. If two enums in a file would get the same
  constructor, both keep their name in front (`ColourRed`, `LightRed`)
- nested messages and enums are `Outer_Inner`
- a message that contains itself is a newtype
- types from other `.proto` files come from their modules
- fields the decoder doesn't know are skipped
- the encoder writes fields in the order of their numbers, and map entries by key, so you get the
  same bytes as protobuf-es (protoc-gen-go puts `oneof` fields last, but otherwise matches too)

Every message is decoded in one loop that reads a field per step. On Go that's the fastest way
for any width: with 50 fields it's 385 ns against 430 for the other way, with 5 fields 32 against
38, and the loop wins by even more when most fields are left out.

The other way is `fields_threshold`: messages with at least that many plain fields are decoded in
two steps, first noting where each field starts and then reading them all. If you only run on
JavaScript, `fields_threshold=10` is worth it: on Bun two steps take half the time from 20 fields
up (50 fields: 860 ns against 1,930).

### Not there yet

Editions, groups, extensions, services, proto2 default values (you get a `Nothing`), closed proto2
enums (they're open like proto3's), merging a message field that appears twice (the last one
wins), keeping unknown fields, JSON.

## Benchmarks

Three messages from [bench/proto/bench.proto](bench/proto/bench.proto), with codecs generated by
`protoc-gen-purescript`:

- **nested**: a bit of everything in 164 bytes: numbers, an `int64`, strings, a packed field, a
  nested message, a map, repeated strings
- **repeated-nested**: 1,000 small nested messages
- **wide**: 50 fields of which the program reads three

Go is what we tune for. Median of seven runs on an Apple M5 Max (load average around 3 while
it ran). Go 1.27, Iris 0.1.17-go.2.

| Go (ns/op · allocs/op) | nested encode | nested decode | repeated-nested encode | repeated-nested decode | wide encode | wide decode |
| --- | --- | --- | --- | --- | --- | --- |
| yoga-protobuf (Iris) | 143 ns · 1 | 344 ns · 19 | 10,835 ns · 1 | 19,650 ns · 1009 | 245 ns · 1 | 357 ns · 11 |
| protoc-gen-go | 645 ns · 21 | 730 ns · 36 | 24,536 ns · 1 | 45,768 ns · 2012 | 369 ns · 1 | 405 ns · 11 |
| vtprotobuf | 182 ns · 1 | 315 ns · 18 | 6,751 ns · 1 | 22,025 ns · 2012 | 106 ns · 1 | 242 ns · 11 |
| hyperpb | – | 255 ns · 2 | – | 17,559 ns · 1 | – | 334 ns · 2 |
| hyperpb (profile-guided) | – | 254 ns · 2 | – | 16,374 ns · 1 | – | 333 ns · 2 |

So: faster than protoc-gen-go everywhere, faster than vtprotobuf at encoding nested messages and
decoding repeated ones, and slower than it on the rest. Some of that isn't a fair fight:

- vtprotobuf doesn't check that strings are UTF-8, neither when it decodes nor when it encodes.
  protoc-gen-go and this library do, as proto3 says to.
- hyperpb only decodes, into an arena it reuses, and its strings point into the input. That's
  where its 2 allocations come from.
- a `map` field here is a `Data.Map`, a tree with a node per entry, where Go's maps are a couple
  of allocations however many entries there are. That's most of the difference on nested.

On Bun it's in between protobuf-es and protobufjs. By default wide decodes in a loop, which is the
slow way on JavaScript; with `fields_threshold=10` it's about 1,000 ns.

| Bun (ns/op) | nested encode | nested decode | repeated-nested encode | repeated-nested decode | wide encode | wide decode |
| --- | --- | --- | --- | --- | --- | --- |
| yoga-protobuf | 624 ns | 804 ns | 42,320 ns | 43,313 ns | 909 ns | 2,120 ns |
| protobuf-es | 621 ns | 1,034 ns | 50,738 ns | 93,459 ns | 1,524 ns | 1,417 ns |
| protobufjs (static) | 708 ns | 527 ns | 62,139 ns | 34,214 ns | 1,138 ns | 644 ns |

### The generator itself

On Kubernetes' `core/v1` and the apimachinery protos it imports, plus the well-known types,
`descriptor.proto`, `plugin.proto` and this repository's test schemas (a 1.2 MB request, 1.9 MB of
PureScript out):

| | per run | binary |
| --- | --- | --- |
| native (Iris) | 88 ms | 2.4 MB |
| Bun | 326 ms | Bun (57 MB) and 3.7 MB of JavaScript |

On a small file it's 16 ms against 69 ms, most of which is Bun starting up.

### Running them

You need Go, Bun, `protoc`, `spago`, `purs-backend-es` and `iris` on your `PATH`.

```
bench/run.sh
```

It builds everything, runs each implementation five times, one after the other in each round
(`RUNS=9 bench/run.sh` for more), prints the tables above with the machine's load, and keeps the
raw numbers in `bench/results`. Before measuring, the
PureScript program checks that it reads what protoc-gen-go wrote for each sample and writes exactly
those bytes back.

## Tests

The specs are a program, so they run on both backends:

```
spago build -p yoga-protobuf-test
bun -e "import('./output-es/Test.Main/index.js').then(spec => spec.main())"
iris run --go -p yoga-protobuf-test --main Test.Main
```

They cover every generator feature with [spec/proto](spec/proto), against bytes protoc-gen-go and
protobuf-es wrote ([spec/fixtures](spec/fixtures)). After changing the generator, `bin/regenerate`
regenerates all the generated code and checks that the generator still generates itself.
