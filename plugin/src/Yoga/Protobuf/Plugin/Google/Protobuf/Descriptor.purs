-- | Bootstrap: the part of google/protobuf/descriptor.proto the generator reads, decoded by
-- | hand, with the names and types the generator gives them. The generator replaces this
-- | module with its own output for descriptor.proto.
module Yoga.Protobuf.Plugin.Google.Protobuf.Descriptor where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Function.Uncurried (mkFn3, runFn3)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Tuple.Nested (type (/\), (/\))
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Decode (Reader)
import Yoga.Protobuf.Error (DecodeError(..), failure)
import Yoga.Protobuf.Wire as Wire

type FileDescriptorProto =
  { name :: Maybe String
  , package :: Maybe String
  , dependency :: Array String
  , messageType :: Array DescriptorProto
  , enumType :: Array EnumDescriptorProto
  , syntax :: Maybe String
  }

newtype DescriptorProto = DescriptorProto
  { name :: Maybe String
  , field :: Array FieldDescriptorProto
  , nestedType :: Array DescriptorProto
  , enumType :: Array EnumDescriptorProto
  , options :: Maybe MessageOptions
  , oneofDecl :: Array OneofDescriptorProto
  }

derive instance Newtype DescriptorProto _

type FieldDescriptorProto =
  { name :: Maybe String
  , number :: Maybe Int
  , label :: Maybe FieldDescriptorProto_Label
  , type :: Maybe FieldDescriptorProto_Type
  , typeName :: Maybe String
  , oneofIndex :: Maybe Int
  , jsonName :: Maybe String
  , options :: Maybe FieldOptions
  , proto3Optional :: Maybe Boolean
  }

data FieldDescriptorProto_Type
  = TypeDouble
  | TypeFloat
  | TypeInt64
  | TypeUint64
  | TypeInt32
  | TypeFixed64
  | TypeFixed32
  | TypeBool
  | TypeString
  | TypeGroup
  | TypeMessage
  | TypeBytes
  | TypeUint32
  | TypeEnum
  | TypeSfixed32
  | TypeSfixed64
  | TypeSint32
  | TypeSint64
  | FieldDescriptorProto_TypeUnrecognized Int

derive instance Eq FieldDescriptorProto_Type

data FieldDescriptorProto_Label
  = Optional
  | Repeated
  | Required
  | FieldDescriptorProto_LabelUnrecognized Int

derive instance Eq FieldDescriptorProto_Label

type OneofDescriptorProto = { name :: Maybe String }

type EnumDescriptorProto =
  { name :: Maybe String
  , value :: Array EnumValueDescriptorProto
  }

type EnumValueDescriptorProto =
  { name :: Maybe String
  , number :: Maybe Int
  }

type MessageOptions = { mapEntry :: Maybe Boolean }

type FieldOptions = { packed :: Maybe Boolean }

toFieldDescriptorProto_Type :: Int -> FieldDescriptorProto_Type
toFieldDescriptorProto_Type = case _ of
  1 -> TypeDouble
  2 -> TypeFloat
  3 -> TypeInt64
  4 -> TypeUint64
  5 -> TypeInt32
  6 -> TypeFixed64
  7 -> TypeFixed32
  8 -> TypeBool
  9 -> TypeString
  10 -> TypeGroup
  11 -> TypeMessage
  12 -> TypeBytes
  13 -> TypeUint32
  14 -> TypeEnum
  15 -> TypeSfixed32
  16 -> TypeSfixed64
  17 -> TypeSint32
  18 -> TypeSint64
  number -> FieldDescriptorProto_TypeUnrecognized number

toFieldDescriptorProto_Label :: Int -> FieldDescriptorProto_Label
toFieldDescriptorProto_Label = case _ of
  1 -> Optional
  2 -> Required
  3 -> Repeated
  number -> FieldDescriptorProto_LabelUnrecognized number

readFileDescriptorProto :: Reader FileDescriptorProto
readFileDescriptorProto = messageOf
  { name: Nothing, package: Nothing, dependency: [], messageType: [], enumType: [], syntax: Nothing }
  case _ of
    10 -> string \value record -> record { name = Just value }
    18 -> string \value record -> record { package = Just value }
    26 -> string \value record -> record { dependency = Array.snoc record.dependency value }
    34 -> message readDescriptorProto \value record -> record { messageType = Array.snoc record.messageType value }
    42 -> message readEnumDescriptorProto \value record -> record { enumType = Array.snoc record.enumType value }
    98 -> string \value record -> record { syntax = Just value }
    _ -> skip

readDescriptorProto :: Reader DescriptorProto
readDescriptorProto = mkFn3 \input start end ->
  map DescriptorProto (runFn3 readRecord input start end)
  where
  readRecord = messageOf
    { name: Nothing, field: [], nestedType: [], enumType: [], options: Nothing, oneofDecl: [] }
    case _ of
      10 -> string \value record -> record { name = Just value }
      18 -> message readFieldDescriptorProto \value record -> record { field = Array.snoc record.field value }
      26 -> message readDescriptorProto \value record -> record { nestedType = Array.snoc record.nestedType value }
      34 -> message readEnumDescriptorProto \value record -> record { enumType = Array.snoc record.enumType value }
      58 -> message readMessageOptions \value record -> record { options = Just value }
      66 -> message readOneofDescriptorProto \value record -> record { oneofDecl = Array.snoc record.oneofDecl value }
      _ -> skip

readFieldDescriptorProto :: Reader FieldDescriptorProto
readFieldDescriptorProto = messageOf
  { name: Nothing
  , number: Nothing
  , label: Nothing
  , type: Nothing
  , typeName: Nothing
  , oneofIndex: Nothing
  , jsonName: Nothing
  , options: Nothing
  , proto3Optional: Nothing
  }
  case _ of
    10 -> string \value record -> record { name = Just value }
    24 -> varint \value record -> record { number = Just value }
    32 -> varint \value record -> record { label = Just (toFieldDescriptorProto_Label value) }
    40 -> varint \value record -> record { type = Just (toFieldDescriptorProto_Type value) }
    50 -> string \value record -> record { typeName = Just value }
    66 -> message readFieldOptions \value record -> record { options = Just value }
    72 -> varint \value record -> record { oneofIndex = Just value }
    82 -> string \value record -> record { jsonName = Just value }
    136 -> varint \value record -> record { proto3Optional = Just (value /= 0) }
    _ -> skip

readOneofDescriptorProto :: Reader OneofDescriptorProto
readOneofDescriptorProto = messageOf { name: Nothing } case _ of
  10 -> string \value record -> record { name = Just value }
  _ -> skip

readEnumDescriptorProto :: Reader EnumDescriptorProto
readEnumDescriptorProto = messageOf { name: Nothing, value: [] } case _ of
  10 -> string \value record -> record { name = Just value }
  18 -> message readEnumValueDescriptorProto \value record -> record { value = Array.snoc record.value value }
  _ -> skip

readEnumValueDescriptorProto :: Reader EnumValueDescriptorProto
readEnumValueDescriptorProto = messageOf { name: Nothing, number: Nothing } case _ of
  10 -> string \value record -> record { name = Just value }
  16 -> varint \value record -> record { number = Just value }
  _ -> skip

readMessageOptions :: Reader MessageOptions
readMessageOptions = messageOf { mapEntry: Nothing } case _ of
  56 -> varint \value record -> record { mapEntry = Just (value /= 0) }
  _ -> skip

readFieldOptions :: Reader FieldOptions
readFieldOptions = messageOf { packed: Nothing } case _ of
  16 -> varint \value record -> record { packed = Just (value /= 0) }
  _ -> skip

-- | Reads the field whose tag ends at the position it's given, up to `end`, into the record:
-- | where the field ends and the record with it.
type Field a = Bytes -> Int -> Int -> Int -> a -> Either DecodeError (Int /\ a)

-- | The reader of a message whose fields `fieldFor` reads, by tag, starting from `empty`.
messageOf :: forall a. a -> (Int -> Field a) -> Reader a
messageOf empty fieldFor = mkFn3 \input start end -> loop input end start empty
  where
  loop input end position record
    | position >= end = Right record
    | otherwise = do
        let afterTag = Wire.varintEnd input position end
        if afterTag < 0 then Left (failure afterTag position)
        else do
          let tag = Wire.varint32 input position
          case fieldFor tag input tag afterTag end record of
            Left error -> Left error
            Right (next /\ updated) -> loop input end next updated

varint :: forall a. (Int -> a -> a) -> Field a
varint update input _ afterTag end record = do
  let next = Wire.varintEnd input afterTag end
  if next < 0 then Left (failure next afterTag)
  else Right (next /\ update (Wire.varint32 input afterTag) record)

string :: forall a. (String -> a -> a) -> Field a
string update input _ afterTag end record = do
  let payload = Wire.varintEnd input afterTag end
  let next = Wire.delimitedEnd input afterTag payload end
  if next < 0 then Left (failure next afterTag)
  else do
    let text = Wire.string input payload next
    if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
    else Right (next /\ update text record)

message :: forall a b. Reader b -> (b -> a -> a) -> Field a
message read update input _ afterTag end record = do
  let payload = Wire.varintEnd input afterTag end
  let next = Wire.delimitedEnd input afterTag payload end
  if next < 0 then Left (failure next afterTag)
  else case runFn3 read input payload next of
    Left error -> Left error
    Right value -> Right (next /\ update value record)

skip :: forall a. Field a
skip input tag afterTag end record = do
  let next = Wire.skip input tag afterTag end
  if next < 0 then Left (failure next afterTag)
  else Right (next /\ record)
