-- | The types protoc-gen-purescript generates for yoga-connect, from spec/proto/ticker.proto and
-- | typed.proto: they print the `.proto` they came from, and their messages go over the wire as
-- | the codecs it generates with `legacy` do (in Yoga.Protobuf.Codecs), which the other specs
-- | test against protoc-gen-go and protobuf-es.
module Test.Typed.TypedSpec where

import Prelude

import Data.Either (Either(..))
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Data.Map as Map
import Data.Newtype (un)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Data.Tuple.Nested ((/\))
import Data.Variant (Variant)
import Data.Variant as Variant
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Type.Proxy (Proxy(..))
import Yoga.Connect.Proto (printProto)
import Yoga.Connect.Protobuf as Protobuf
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Codecs.Imported as LegacyImported
import Yoga.Protobuf.Codecs.Ticker.V1.Ticker as LegacyTicker
import Yoga.Protobuf.Codecs.Typed.V1.Typed as Legacy
import Yoga.Protobuf.Plugin.Generate (generate)
import Yoga.Protobuf.Plugin.Google.Protobuf.Compiler.Plugin (defaultCodeGeneratorRequest)
import Yoga.Protobuf.Plugin.Google.Protobuf.Descriptor (DescriptorProto(..), EnumDescriptorProto, FieldDescriptorProto_Label(..), FieldDescriptorProto_Type(..), FileDescriptorProto, ServiceDescriptorProto, defaultDescriptorProto, defaultEnumDescriptorProto, defaultFieldDescriptorProto, defaultFileDescriptorProto, defaultMethodDescriptorProto, defaultServiceDescriptorProto)
import Yoga.Protobuf.Typed.Imported as Imported
import Yoga.Connect.Schema (BidiStream, ServerStream, Service)
import Yoga.Protobuf.Typed.Ticker.V1.Ticker (Fill, Quote, Subscribe, Ticker, TickerWith, Trade)
import Yoga.Protobuf.Typed.Typed.V1.Typed (Clock_Kind(..), Lobby, Side(..), Table)
import Yoga.Protobuf.Unsigned (UInt32(..), UInt64(..))

spec :: Spec Unit
spec = describe "types for yoga-connect" do
  describe "ticker.proto" do
    it "prints the .proto it came from" do
      printProto @Ticker `shouldEqual` tickerProto
    it "takes a row of errors for each method, in the order of their names" do
      printProto @(TickerWith TradeErrors (notFound :: String)) `shouldEqual` printProto @HandWrittenTicker
    it "encodes each message to the bytes the legacy codecs write" do
      Protobuf.encode @Subscribe subscribe `shouldEqual` LegacyTicker.encodeSubscribe subscribe
      Protobuf.encode @Quote quote `shouldEqual` LegacyTicker.encodeQuote quote
      Protobuf.encode @Trade trade `shouldEqual` LegacyTicker.encodeTrade trade
      Protobuf.encode @Fill fill `shouldEqual` LegacyTicker.encodeFill fill
    it "decodes the bytes the legacy codecs write" do
      Protobuf.decode @Quote (LegacyTicker.encodeQuote quote) `shouldEqual` Right quote
      Protobuf.decode @Fill (LegacyTicker.encodeFill fill) `shouldEqual` Right fill

  describe "typed.proto" do
    it "prints the .proto it came from, with every message and enum by its name" do
      printProto @Lobby `shouldEqual` lobbyProto
    it "encodes every kind of field to the bytes the legacy codecs write" do
      Protobuf.encode @Table table `shouldEqual` Legacy.encodeTable legacyTable
    it "decodes the bytes the legacy codecs write" do
      Protobuf.decode @Table (Legacy.encodeTable legacyTable) `shouldEqual` Right table

  describe "the generator" do
    it "writes types by default" do
      contentOf (generated Nothing [ quoteFile ]) `shouldSatisfy` contains "type Quote = Message { symbol :: 1 := String }"
    it "writes codecs with the option legacy" do
      contentOf (generated (Just "legacy") [ quoteFile ]) `shouldSatisfy` contains "decodeQuote :: Bytes -> Either DecodeError Quote"
    it "refuses what the types can't say, and says to use legacy" do
      errorOf (generated Nothing [ quoteFile # withField TypeFloat ]) `shouldEqual` Just "quotes.Quote.symbol: yoga-connect's messages have no float; use double, or generate with the option legacy"
      errorOf (generated Nothing [ quoteFile { syntax = Just "proto2" } ]) `shouldEqual` Just "quotes.proto: yoga-connect's messages are proto3; generate proto2 files with the option legacy"
      errorOf (generated Nothing [ quoteFile { enumType = [ gappedEnum ] } ]) `shouldEqual` Just "quotes.Gapped: an enum's values need the numbers 0, 1, 2, … in their order; generate it with the option legacy"
      errorOf (generated Nothing [ quoteFile { service = [ lowerCaseMethod ] } ]) `shouldEqual` Just "quotes.Quotes.get_quote: yoga-connect would call it GetQuote; rename it, or generate with the option legacy"
    it "takes what the types can't say with the option legacy" do
      generated (Just "legacy") [ quoteFile # withField TypeFloat ] `shouldSatisfy` (errorOf >>> eq Nothing)
  where
  contains text = String.contains (Pattern text)
  generated parameter files = generate defaultCodeGeneratorRequest { fileToGenerate = [ "quotes.proto" ], parameter = parameter, protoFile = files }
  contentOf response = response.file # map (_.content >>> fromMaybe "") # String.joinWith "\n"
  errorOf response = response.error

-- | The ticker as it's written by hand, with errors, which `TickerWith` is too.
type HandWrittenTicker = Service "ticker.v1.Ticker"
  { watch :: ServerStream Subscribe Quote (notFound :: String)
  , trade :: BidiStream Trade Fill TradeErrors
  }

type TradeErrors = (notFound :: String, outOfStock :: Int)

sameAsHandWritten :: Proxy HandWrittenTicker -> Proxy (TickerWith TradeErrors (notFound :: String))
sameAsHandWritten = identity

subscribe :: { symbols :: Array String }
subscribe = { symbols: [ "ACME", "GLOBEX" ] }

quote :: { symbol :: String, price :: Number, average :: Number }
quote = { symbol: "ACME", price: 121.5, average: 121.25 }

trade :: { symbol :: String, quantity :: Int, limit :: Number }
trade = { symbol: "INITECH", quantity: -40, limit: 9.9 }

fill :: { symbol :: String, quantity :: Int, price :: Number, position :: Int }
fill = { symbol: "ACME", quantity: 10, price: 121.4, position: 10 }

-- | What handlers and clients see of `Table`: a map is an array of entries, a `oneof` a `Variant`.
type TypedTable =
  { name :: String
  , players :: Array TypedPlayer
  , round :: Maybe Int
  , scores :: Array { key :: String, value :: Int64 }
  , side :: Side
  , winner :: Side
  , mascot :: { name :: String, mood :: Imported.Mood }
  , clock :: TypedClock
  , status :: Variant (waitingFor :: String, wonBy :: Side, expired :: { at :: Int64 })
  , snapshot :: Bytes
  , seats :: UInt32
  , games :: UInt64
  , open :: Boolean
  , sides :: Array Side
  , byName :: Array { key :: String, value :: TypedPlayer }
  , spareClock :: Maybe TypedClock
  }

type TypedPlayer = { name :: String, side :: Side, rating :: Number }

type TypedClock = { remaining :: Int64, kind :: Clock_Kind, expiry :: { at :: Int64 } }

-- | A table with every field set, as the types' handlers see it.
table :: TypedTable
table =
  { name: "the corner"
  , players: [ ann, bob ]
  , round: Just 3
  , scores: [ { key: "ann", value: Int64.fromInt 12 }, { key: "bob", value: Int64.fromInt 9 } ]
  , side: White
  , winner: Black
  , mascot: { name: "owl", mood: Imported.Happy }
  , clock: { remaining: Int64.fromInt 90, kind: Classical, expiry: { at: Int64.fromInt 1700 } }
  , status: Variant.inj (Proxy :: Proxy "wonBy") Black
  , snapshot: Bytes.fromArray [ 1, 2, 3 ]
  , seats: UInt32 4
  , games: UInt64 (Int64.fromInt 7)
  , open: true
  , sides: [ White, Black, White ]
  , byName: [ { key: "ann", value: ann } ]
  , spareClock: Just { remaining: Int64.fromInt 30, kind: Blitz, expiry: { at: Int64.fromInt 1800 } }
  }
  where
  ann = { name: "ann", side: White, rating: 1500.5 }
  bob = { name: "bob", side: Black, rating: 1490.0 }

-- | The same table, as the legacy codecs see it.
legacyTable :: Legacy.Table
legacyTable =
  { name: "the corner"
  , players: [ ann, bob ]
  , round: Just 3
  , scores: Map.fromFoldable [ "ann" /\ Int64.fromInt 12, "bob" /\ Int64.fromInt 9 ]
  , side: Legacy.White
  , winner: Legacy.Black
  , mascot: Just { name: "owl", mood: LegacyImported.Happy }
  , clock: Just { remaining: Int64.fromInt 90, kind: Legacy.Classical, expiry: Just { at: Int64.fromInt 1700 } }
  , status: Just (Variant.inj (Proxy :: Proxy "wonBy") Legacy.Black)
  , snapshot: Bytes.fromArray [ 1, 2, 3 ]
  , seats: UInt32 4
  , games: UInt64 (Int64.fromInt 7)
  , open: true
  , sides: [ Legacy.White, Legacy.Black, Legacy.White ]
  , byName: Map.fromFoldable [ "ann" /\ ann ]
  , spareClock: Just { remaining: Int64.fromInt 30, kind: Legacy.Blitz, expiry: Just { at: Int64.fromInt 1800 } }
  }
  where
  ann = { name: "ann", side: Legacy.White, rating: 1500.5 }
  bob = { name: "bob", side: Legacy.Black, rating: 1490.0 }

-- | `printProto @Ticker`: ticker.proto, without its comments.
tickerProto :: String
tickerProto =
  """syntax = "proto3";

package ticker.v1;

service Ticker {
  rpc Trade(stream Trade) returns (stream Fill);
  rpc Watch(Subscribe) returns (stream Quote);
}

message Trade {
  string symbol = 1;
  int32 quantity = 2;
  double limit = 3;
}

message Fill {
  string symbol = 1;
  int32 quantity = 2;
  double price = 3;
  int32 position = 4;
}

message Subscribe {
  repeated string symbols = 1;
}

message Quote {
  string symbol = 1;
  double price = 2;
  double average = 3;
}
"""

-- | `printProto @Lobby`: typed.proto, without its comments, and the messages the service uses.
lobbyProto :: String
lobbyProto =
  """syntax = "proto3";

package typed.v1;

service Lobby {
  rpc GetTable(TableRequest) returns (Table);
  rpc Play(stream Move) returns (stream Move);
  rpc Seat(stream Player) returns (Seated);
  rpc WatchTables(TableRequest) returns (stream Table);
}

message TableRequest {
  string name = 1;
}

message Table {
  string name = 1;
  repeated Player players = 2;
  optional int32 round = 3;
  repeated ScoresEntry scores = 4;
  Side side = 5;
  Side winner = 6;
  Thing mascot = 7;
  Clock clock = 8;
  oneof status {
    string waiting_for = 9;
    Side won_by = 10;
    Expiry expired = 11;
  }
  bytes snapshot = 12;
  uint32 seats = 13;
  uint64 games = 14;
  bool open = 15;
  repeated Side sides = 16;
  repeated ByNameEntry by_name = 17;
  optional Clock spare_clock = 18;
}

message Move {
  string from = 1;
  string to = 2;
}

message Player {
  string name = 1;
  Side side = 2;
  double rating = 3;
}

message Seated {
  int32 count = 1;
}

message ByNameEntry {
  string key = 1;
  Player value = 2;
}

message Clock {
  int64 remaining = 1;
  Kind kind = 2;
  Expiry expiry = 3;
}

message Expiry {
  int64 at = 1;
}

enum Kind {
  KIND_BLITZ = 0;
  KIND_CLASSICAL = 1;
}

enum Mood {
  MOOD_UNSPECIFIED = 0;
  MOOD_HAPPY = 1;
  MOOD_GRUMPY = 2;
}

message ScoresEntry {
  string key = 1;
  int64 value = 2;
}

enum Side {
  SIDE_UNSPECIFIED = 0;
  SIDE_WHITE = 1;
  SIDE_BLACK = 2;
}

message Thing {
  string name = 1;
  Mood mood = 2;
}
"""

-- | `quotes.proto`: `message Quote { string symbol = 1; }`.
quoteFile :: FileDescriptorProto
quoteFile = defaultFileDescriptorProto
  { name = Just "quotes.proto"
  , package = Just "quotes"
  , syntax = Just "proto3"
  , messageType = [ message "Quote" TypeString ]
  }

withField :: FieldDescriptorProto_Type -> FileDescriptorProto -> FileDescriptorProto
withField fieldType file = file { messageType = [ message "Quote" fieldType ] }

message :: String -> FieldDescriptorProto_Type -> DescriptorProto
message name fieldType = DescriptorProto (un DescriptorProto defaultDescriptorProto) { name = Just name, field = [ field ] }
  where
  field = defaultFieldDescriptorProto { name = Just "symbol", number = Just 1, label = Just Optional, type = Just fieldType }

-- | `enum Gapped { GAPPED_ZERO = 0; GAPPED_TWO = 2; }`
gappedEnum :: EnumDescriptorProto
gappedEnum = defaultEnumDescriptorProto
  { name = Just "Gapped"
  , value = [ { name: Just "GAPPED_ZERO", number: Just 0, options: Nothing }, { name: Just "GAPPED_TWO", number: Just 2, options: Nothing } ]
  }

-- | `service Quotes { rpc get_quote(Quote) returns (Quote); }`
lowerCaseMethod :: ServiceDescriptorProto
lowerCaseMethod = defaultServiceDescriptorProto
  { name = Just "Quotes"
  , method = [ defaultMethodDescriptorProto { name = Just "get_quote", inputType = Just ".quotes.Quote", outputType = Just ".quotes.Quote" } ]
  }
