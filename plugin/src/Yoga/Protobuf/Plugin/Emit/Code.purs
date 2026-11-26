-- | What the decoders, encoders and declarations of a generated module share: how a value's
-- | type, default and wire format are written down, and how lines of code are laid out.
module Yoga.Protobuf.Plugin.Emit.Code
  ( WireType(..)
  , InMessage
  , valueType
  , zeroOf
  , initial
  , fieldsOf
  , wireTypeOf
  , wireNumber
  , tagOf
  , recordLines
  , indentBy
  , parenthesised
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (foldMap)
import Data.Int.Bits (shl, (.&.), (.|.))
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))

import Yoga.Protobuf.Plugin.Schema (Field, Member(..), MessageModel, Shape(..), ValueType(..))

-- | How a value is laid out in the encoding.
data WireType = Varint | SixtyFourBits | LengthDelimited | ThirtyTwoBits

-- | A field of a message, with the decoder's variable it goes into, and its `oneof`, if any.
type InMessage = { field :: Field, into :: String, oneof :: Maybe String }

-- | The PureScript type of a value.
valueType :: ValueType -> String
valueType = case _ of
  DoubleValue -> "Number"
  FloatValue -> "Number"
  Int64Value -> "Int64"
  UInt64Value -> "UInt64"
  Int32Value -> "Int"
  Fixed64Value -> "UInt64"
  Fixed32Value -> "UInt32"
  BoolValue -> "Boolean"
  StringValue -> "String"
  BytesValue -> "Bytes"
  UInt32Value -> "UInt32"
  SFixed32Value -> "Int"
  SFixed64Value -> "Int64"
  SInt32Value -> "Int"
  SInt64Value -> "Int64"
  MessageValue reference -> reference.qualifier <> reference.name
  EnumValue reference -> reference.qualifier <> reference.name

-- | A value's default.
zeroOf :: ValueType -> String
zeroOf = case _ of
  DoubleValue -> "0.0"
  FloatValue -> "0.0"
  Int64Value -> "zero"
  UInt64Value -> "(UInt64 zero)"
  Int32Value -> "0"
  Fixed64Value -> "(UInt64 zero)"
  Fixed32Value -> "(UInt32 0)"
  BoolValue -> "false"
  StringValue -> "\"\""
  BytesValue -> "Bytes.empty"
  UInt32Value -> "(UInt32 0)"
  SFixed32Value -> "0"
  SFixed64Value -> "zero"
  SInt32Value -> "0"
  SInt64Value -> "zero"
  MessageValue reference -> reference.qualifier <> "default" <> reference.name
  EnumValue reference -> reference.qualifier <> reference.zero

-- | What the decoder starts a field with: its default, or nothing yet.
initial :: Field -> String
initial field = case field.shape of
  Implicit -> zeroOf field.value
  Required -> zeroOf field.value
  Optional -> "Nothing"
  Repeated _ -> "Repeated.empty"
  MapOf _ -> "Repeated.empty"
  InOneof -> "Nothing"

-- | The fields of the message, those of its `oneof`s too.
fieldsOf :: MessageModel -> Array InMessage
fieldsOf message = Array.concatMap fieldsOfMember message.members
  where
  fieldsOfMember = case _ of
    Plain field -> [ { field, into: field.variable, oneof: Nothing } ]
    Oneof oneof -> map (\field -> { field, into: oneof.variable, oneof: Just oneof.label }) oneof.fields

-- | How a value of this type is laid out.
wireTypeOf :: ValueType -> WireType
wireTypeOf = case _ of
  DoubleValue -> SixtyFourBits
  Fixed64Value -> SixtyFourBits
  SFixed64Value -> SixtyFourBits
  FloatValue -> ThirtyTwoBits
  Fixed32Value -> ThirtyTwoBits
  SFixed32Value -> ThirtyTwoBits
  StringValue -> LengthDelimited
  BytesValue -> LengthDelimited
  MessageValue _ -> LengthDelimited
  Int64Value -> Varint
  UInt64Value -> Varint
  Int32Value -> Varint
  BoolValue -> Varint
  UInt32Value -> Varint
  SInt32Value -> Varint
  SInt64Value -> Varint
  EnumValue _ -> Varint

-- | The number a tag has in its lowest three bits for the wire type.
wireNumber :: WireType -> Int
wireNumber = case _ of
  Varint -> 0
  SixtyFourBits -> 1
  LengthDelimited -> 2
  ThirtyTwoBits -> 5

-- | The tag of a field: its number and wire type.
tagOf :: Int -> WireType -> Int
tagOf number wire = lowBits .|. signBit
  where
  lowBits = ((number .&. 0x0FFFFFFF) `shl` 3) .|. wireNumber wire
  signBit = if number .&. 0x10000000 == 0 then 0 else -2147483647 - 1

-- | A record's fields one per line, or on one line if they're few and short.
recordLines :: Array String -> Array String
recordLines fields = case fields of
  [] -> [ "{}" ]
  _
    | String.length oneLine <= 60 -> [ oneLine ]
    | otherwise -> Array.mapWithIndex (\index field -> (if index == 0 then "{ " else ", ") <> field) fields <> [ "}" ]
  where
  oneLine = "{ " <> String.joinWith ", " fields <> " }"

-- | The lines indented by `count` spaces, except empty ones.
indentBy :: Int -> Array String -> Array String
indentBy count lines = map (\line -> if line == "" then line else spaces <> line) lines
  where
  spaces = foldMap (const " ") (Array.range 1 count)

-- | The expression in parentheses, unless it's one word or already in brackets.
parenthesised :: String -> String
parenthesised text
  | String.contains (Pattern " ") text && not (String.take 1 text == "(" || String.take 1 text == "{") = "(" <> text <> ")"
  | otherwise = text
