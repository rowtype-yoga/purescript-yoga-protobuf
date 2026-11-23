-- | The encoders of a generated module. They write back to front: the last field first, each
-- | value before its tag, and a nested message before its length.
module Yoga.Protobuf.Plugin.Emit.Encoder
  ( writer
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (fromMaybe)

import Yoga.Protobuf.Plugin.Emit.Code (InMessage, WireType(..), fieldsOf, indentBy, tagOf, wireTypeOf)
import Yoga.Protobuf.Plugin.Names (lowerFirst)
import Yoga.Protobuf.Plugin.Schema (MessageModel, Packing(..), Shape(..), ValueType(..))

-- | `writeX :: Writer -> X -> Effect Unit`, which writes the fields from the highest number down.
writer :: MessageModel -> Array String
writer message = case writes of
  [] -> [ signature, "write" <> message.name <> " _ _ = pure unit" ]
  _
    | message.recursive ->
        [ signature
        , "write" <> message.name <> " writer " <> wrapped <> " = do"
        , "  let message = un " <> message.name <> " " <> wrapped
        ]
          <> indentBy 2 (Array.concat writes)
    | otherwise ->
        [ signature, "write" <> message.name <> " writer message = do" ] <> indentBy 2 (Array.concat writes)
  where
  signature = "write" <> message.name <> " :: Writer -> " <> message.name <> " -> Effect Unit"
  wrapped = if Array.elem (lowerFirst message.name) [ "writer", "message" ] then lowerFirst message.name <> "'" else lowerFirst message.name
  descending = Array.sortBy (\left right -> compare right.field.number left.field.number) (fieldsOf message)
  writes = map writeField descending

writeField :: InMessage -> Array String
writeField { field, oneof } = case field.shape of
  Implicit -> [ "when " <> isSet field.value access <> " do" ] <> indentBy 2 (writeValue "mark" field.number field.value access)
  Required -> case field.value of
    -- Its own block, so that its `mark` doesn't shadow another field's.
    MessageValue _ -> [ "do" ] <> indentBy 2 (writeValue "mark" field.number field.value access)
    _ -> writeValue "mark" field.number field.value access
  Optional -> present access
  InOneof -> present (access <> " >>= Variant.prj (Proxy :: _ \"" <> field.label <> "\")")
  Repeated Packed ->
    [ "when (not (Array.null " <> access <> ")) do"
    , "  mark <- Writer.written writer"
    , "  Writer.eachDescending " <> access <> " \\item -> " <> writeBare field.value "item"
    , "  Writer.lengthSince writer mark"
    , "  Writer.tag writer " <> show (tagOf field.number LengthDelimited)
    ]
  Repeated Expanded ->
    [ "Writer.eachDescending " <> access <> " \\item -> do" ] <> indentBy 2 (writeValue "mark" field.number field.value "item")
  MapOf entry ->
    [ "Writer.eachEntryDescending " <> access <> " \\key value -> do"
    , "  mark <- Writer.written writer"
    ]
      <> indentBy 2 (writeValue "valueMark" 2 entry.value "value" <> writeValue "keyMark" 1 entry.key "key")
      <> [ "  Writer.lengthSince writer mark"
         , "  Writer.tag writer " <> show (tagOf field.number LengthDelimited)
         ]
  where
  access = "message." <> fromMaybe field.label oneof
  present scrutinee =
    [ "case " <> scrutinee <> " of"
    , "  Nothing -> pure unit"
    , "  Just " <> field.variable <> " -> do"
    ]
      <> indentBy 4 (writeValue "mark" field.number field.value field.variable)

-- | Writes the value and then its tag, as a back-to-front writer has to. A message notes in
-- | `mark` where it started, to write its length after it.
writeValue :: String -> Int -> ValueType -> String -> Array String
writeValue mark number value expression = case value of
  MessageValue reference ->
    [ mark <> " <- Writer.written writer"
    , reference.qualifier <> "write" <> reference.name <> " writer " <> expression
    , "Writer.lengthSince writer " <> mark
    , "Writer.tag writer " <> show (tagOf number LengthDelimited)
    ]
  _ ->
    [ writeBare value expression
    , "Writer.tag writer " <> show (tagOf number (wireTypeOf value))
    ]

-- | Writes the value without a tag.
writeBare :: ValueType -> String -> String
writeBare value expression = case value of
  DoubleValue -> "Writer.double writer " <> expression
  FloatValue -> "Writer.float writer " <> expression
  Int64Value -> "Writer.int64 writer " <> expression
  UInt64Value -> "Writer.int64 writer (un UInt64 " <> expression <> ")"
  Int32Value -> "Writer.int32 writer " <> expression
  Fixed64Value -> "Writer.fixed64 writer (un UInt64 " <> expression <> ")"
  Fixed32Value -> "Writer.fixed32 writer (un UInt32 " <> expression <> ")"
  BoolValue -> "Writer.bool writer " <> expression
  StringValue -> "Writer.string writer " <> expression
  BytesValue -> "Writer.bytes writer " <> expression
  UInt32Value -> "Writer.uint32 writer (un UInt32 " <> expression <> ")"
  SFixed32Value -> "Writer.fixed32 writer " <> expression
  SFixed64Value -> "Writer.fixed64 writer " <> expression
  SInt32Value -> "Writer.sint32 writer " <> expression
  SInt64Value -> "Writer.sint64 writer " <> expression
  EnumValue reference -> "Writer.int32 writer (" <> reference.qualifier <> "from" <> reference.name <> " " <> expression <> ")"
  MessageValue reference -> reference.qualifier <> "write" <> reference.name <> " writer " <> expression

-- | Whether a value differs from its default, so that a field without presence is written.
isSet :: ValueType -> String -> String
isSet value expression = case value of
  BoolValue -> expression
  DoubleValue -> "(" <> expression <> " /= 0.0)"
  FloatValue -> "(" <> expression <> " /= 0.0)"
  Int32Value -> "(" <> expression <> " /= 0)"
  SInt32Value -> "(" <> expression <> " /= 0)"
  SFixed32Value -> "(" <> expression <> " /= 0)"
  Int64Value -> "(" <> expression <> " /= zero)"
  SInt64Value -> "(" <> expression <> " /= zero)"
  SFixed64Value -> "(" <> expression <> " /= zero)"
  UInt32Value -> "(un UInt32 " <> expression <> " /= 0)"
  Fixed32Value -> "(un UInt32 " <> expression <> " /= 0)"
  UInt64Value -> "(un UInt64 " <> expression <> " /= zero)"
  Fixed64Value -> "(un UInt64 " <> expression <> " /= zero)"
  StringValue -> "(" <> expression <> " /= \"\")"
  BytesValue -> "(Bytes.length " <> expression <> " /= 0)"
  EnumValue reference -> "(" <> reference.qualifier <> "from" <> reference.name <> " " <> expression <> " /= 0)"
  MessageValue _ -> "true"
