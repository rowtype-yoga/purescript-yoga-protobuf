# Order report

A shop's day of orders in one protocol buffer file, a million of them. The program reads it,
keeps the shipped orders with their coupons applied, totals up every customer, and writes the
shipped orders and a report back as protocol buffers. The same program with protoc-gen-go is in
[go/](go/), and both write exactly the same bytes.

## The types come from the `.proto`

[proto/shop.proto](proto/shop.proto) has the messages:

```proto
message Order {
  int32 id = 1;
  string customer = 2;
  Status status = 3;
  repeated LineItem items = 4;
  optional string coupon = 5;
}
```

and `protoc-gen-purescript` turns them into records, an enum and codecs in
[src/Proto/Shop.purs](src/Proto/Shop.purs):

```purescript
type Order =
  { id :: Int
  , customer :: String
  , status :: Status
  , items :: Array LineItem
  , coupon :: Maybe String
  }

data Status = Unspecified | Placed | Shipped | Cancelled | StatusUnrecognized Int

decodeOrderLog :: Bytes -> Either DecodeError OrderLog
encodeOrderLog :: OrderLog -> Bytes
```

So the program is ordinary PureScript on records and arrays, and the compiler knows every field
([src/Main.purs](src/Main.purs)):

```purescript
report input shippedPath reportPath = do
  bytes <- readBytes input
  { orders } <- timed "decode" (\_ -> decodeOrderLog bytes) >>= orThrow
  shipped <- timed "ship" \_ -> shipWithCoupons orders
  totals <- timed "total" \_ -> totalsByCustomer shipped
  encoded <- timed "encode" \_ -> inChunks shipped
  writeChunks shippedPath encoded
  writeChunks reportPath [ encodeReport (summary orders shipped totals) ]
  printSummary orders shipped totals

shipWithCoupons :: Array Order -> Array Order
shipWithCoupons orders = orders # Array.filter (_.status >>> eq Shipped) <#> applyCoupon
  where
  applyCoupon order = case order.coupon of
    Just "TENOFF" -> order { items = order.items <#> tenPercentOff, coupon = Nothing }
    _ -> order
  tenPercentOff item = item { unitPriceCents = item.unitPriceCents * 9 / 10 }
```

To make the PureScript again after changing the `.proto`, from the repository's root:

```bash
googoo go -p protoc-gen-purescript --entry Yoga.Protobuf.Plugin.Native.main
protoc --plugin=protoc-gen-purescript=bin/protoc-gen-purescript \
  --purescript_out=module_prefix=Proto:examples/order-report/src \
  -I examples/order-report/proto examples/order-report/proto/shop.proto
```

## Running it

You need googoo 0.1.18-go.3 or newer and Go 1.27 (`brew install spago i-am-the-slime/tap/googoo`).
It gets its packages from the
[Go package set](https://github.com/rowtype-yoga/purescript-go-package-sets) `go-0.1.18-20261126`.

```bash
cd examples/order-report
googoo run --go -- generate 1000000 orders.pb
googoo run --go -- report orders.pb shipped.pb report.pb
```

```
wrote 1000000 orders to orders.pb
decode  164 ms
ship  36 ms
total  97 ms
encode  42 ms
1000000 orders, 700000 shipped, 3500 customers
  customer-4325  $143967.10 in 200 orders
  customer-3125  $143720.40 in 200 orders
  customer-1325  $143580.40 in 200 orders
  customer-3785  $143549.04 in 200 orders
  customer-3525  $143446.30 in 200 orders
```

`orders.pb` is 64 MB, `shipped.pb` 45 MB.

and the same with protoc-gen-go:

```bash
cd go
go run . generate 1000000 orders.pb
go run . report orders.pb shipped.pb report.pb
```

`cmp` says the three files are the same from both.

## Against protoc-gen-go

Both programs time their steps the same way. Medians of 22 runs, the two programs taking turns,
on an Apple M5 Max with Go 1.27 and Iris 0.1.18-go.2 (the machine had other work going on, load
average around 25 to 55, so take the last digit with a pinch of salt):

| | decode 64 MB | ship | total | encode 45 MB | whole run (`time`) |
| --- | ---: | ---: | ---: | ---: | ---: |
| yoga-protobuf | 164 ms | 36 ms | 97 ms | 42 ms | 0.62 s |
| protoc-gen-go | 245 ms | 12 ms | 9 ms | 96 ms | 0.69 s |

- **Decoding is 1.5× faster and encoding 2.3× faster** than protoc-gen-go: the part this library
  does.
- **The rest is slower**, and it isn't protobuf. `total` builds a `Data.Map` of 3,500 customers
  one order at a time, a balanced tree with a string comparison per level, where Go updates a hash
  map in place. `ship` copies the 700,000 shipped orders into a new array of records, where Go
  keeps pointers to the ones it decoded.
- Over the whole process, reading the file included, that comes out at about 10% faster.

### Encode in chunks

`inChunks` encodes 500 orders at a time and writes the pieces one after another. Two `OrderLog`s
in a row are one `OrderLog` with both lists, so the file is byte for byte what one big
`encodeOrderLog` writes. It matters on Go: the writer starts with 1 KB and, when a message doesn't
fit, encodes it again with twice the room. For one 45 MB message that's 17 attempts. Each 500
order chunk fits after a few doublings, and the writer it borrows is kept for the next one.

With one `encodeOrderLog { orders: shipped }` instead, encoding takes 270 to 900 ms instead of
42, and the whole run 0.96 s against 0.69 for protoc-gen-go. protoc-gen-go doesn't have this
problem because it measures the message before writing it.

### Running the comparison

```bash
googoo go                                       # builds .spago/go/order-report/bin/order-report
(cd go && go build -o ../.spago/protoc-gen-go .)
.spago/go/order-report/bin/order-report generate 1000000 orders.pb
.spago/go/order-report/bin/order-report report orders.pb shipped.pb report.pb
.spago/protoc-gen-go report orders.pb go-shipped.pb go-report.pb
cmp shipped.pb go-shipped.pb && cmp report.pb go-report.pb
```

## The Go googoo writes

`googoo go out` puts the Go for this program in `out/`. 0.1.18-go.3 gave it shorter names than
0.1.18-go.2 did: 14.6 characters on average instead of 17.3, the longest 37 instead of 55. There
was no `switch either` to get rid of, before or after.
