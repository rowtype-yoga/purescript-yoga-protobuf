-- | The decoders of a generated module.
-- |
-- | A message's decoder reads one field per step of a loop whose arguments are the fields so far,
-- | which both backends run as a loop over local variables. A message with many plain fields is
-- | read in two steps instead (see `Yoga.Protobuf.Fields`), and a map field's entries with a
-- | decoder of their own.
module Yoga.Protobuf.Plugin.Emit.Decoder
  ( reader
  , entryReader
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (all, maximum)
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.String as String

import Yoga.Protobuf.Plugin.Emit.Code (InMessage, WireType(..), fieldsOf, indentBy, initial, parenthesised, recordLines, tagOf, valueType, wireNumber, wireTypeOf, zeroOf)
import Yoga.Protobuf.Plugin.Names (lowerFirst)
import Yoga.Protobuf.Plugin.Schema (Field, MapEntry, Member(..), MessageModel, Shape(..), ValueType(..))

-- | `readX :: Reader X`: in two steps if the message has at least `fieldsThreshold` fields and
-- | they're all plain values, in a loop otherwise.
reader :: Int -> MessageModel -> Array String
reader fieldsThreshold message
  | twoStep fieldsThreshold message = fieldsReader message
  | otherwise = loopReader message

-- | The reader of a map field's entries.
entryReader :: MapEntry -> Array String
entryReader entry =
  [ entry.reader <> " :: Reader (Entry " <> parenthesised (valueType entry.key) <> " " <> parenthesised (valueType entry.value) <> ")" ]
    <> readerLoop entry.reader variables [ "{ key, value }" ] [ keyBranch, valueBranch ]
  where
  variables =
    [ { name: "key", initial: zeroOf entry.key, final: "key" }
    , { name: "value", initial: zeroOf entry.value, final: "value" }
    ]
  keyBranch = singleBranch 1 entry.key (\read -> "loop next " <> read <> " value")
  valueBranch = singleBranch 2 entry.value (\read -> "loop next key " <> read)

-- Decoding in a loop

-- | A loop variable of the decoder: a plain field, or a whole `oneof`.
type Variable = { name :: String, initial :: String, final :: String }

loopReader :: MessageModel -> Array String
loopReader message =
  [ "read" <> message.name <> " :: Reader " <> message.name ]
    <> readerLoop ("read" <> message.name) variables finish (Array.concatMap branches (fieldsOf message))
  where
  variables = map variableOf message.members
  finish = wrapped message (recordLines (map labelled message.members))
  labelled = case _ of
    Plain field
      | finalOf field == field.label -> field.label
      | otherwise -> field.label <> ": " <> finalOf field
    Oneof oneof
      | oneof.variable == oneof.label -> oneof.label
      | otherwise -> oneof.label <> ": " <> oneof.variable
  variableOf = case _ of
    Plain field -> { name: field.variable, initial: initial field, final: finalOf field }
    Oneof oneof -> { name: oneof.variable, initial: "Nothing", final: oneof.variable }
  finalOf field = case field.shape of
    Repeated _ -> "Repeated.freeze " <> field.variable
    MapOf _ -> "mapFromEntries " <> field.variable
    Implicit -> field.variable
    Required -> field.variable
    Optional -> field.variable
    InOneof -> field.variable
  branches inMessage = fieldBranches (map _.name variables) inMessage

-- | Wraps the record in the newtype of a message that refers to itself.
wrapped :: MessageModel -> Array String -> Array String
wrapped message lines
  | message.recursive = case lines of
      [ single ] -> [ "(" <> message.name <> " " <> single <> ")" ]
      _ -> [ "(" <> message.name ] <> indentBy 4 lines <> [ "  )" ]
  | otherwise = lines

-- | How a value read for the field goes into its loop variable.
updateFor :: Field -> String -> String
updateFor field value = case field.shape of
  Implicit -> value
  Required -> value
  Optional -> "(Just " <> parenthesised value <> ")"
  Repeated _ -> "(Repeated.snoc " <> field.variable <> " " <> parenthesised value <> ")"
  MapOf _ -> "(Repeated.snoc " <> field.variable <> " " <> parenthesised value <> ")"
  InOneof -> "(Just (Variant.inj (Proxy :: _ \"" <> field.label <> "\") " <> parenthesised value <> "))"

-- | The decoder's loop, from `start` to `end`, which reads a field per step with `branches`.
readerLoop :: String -> Array Variable -> Array String -> Array (Array String) -> Array String
readerLoop name variables finish branches =
  [ name <> " = mkFn3 \\input start end -> do"
  , "  let"
  , "    loop " <> String.joinWith " " ([ "position" ] <> map _.name variables)
  ]
    <> finishLines
    <> [ "      | otherwise = do"
       , "          let afterTag = Wire.varintEnd input position end"
       , "          if afterTag < 0 then Left (failure afterTag position)"
       , "          else case Wire.varint32 input position of"
       ]
    <> indentBy 12 (Array.concat branches <> skipBranch)
    <> [ "  loop " <> String.joinWith " " ([ "start" ] <> map _.initial variables) ]
  where
  finishLines = case finish of
    [ single ] -> [ "      | position >= end = Right " <> single ]
    _ -> [ "      | position >= end = Right" ] <> indentBy 10 finish
  skipBranch =
    [ "tag -> do"
    , "  let next = Wire.skip input tag afterTag end"
    , "  if next < 0 then Left (failure next afterTag)"
    , "  else loop next " <> String.joinWith " " (map _.name variables)
    ]

-- | The `case` branches for a field's tags: one for its wire type, and for repeated numbers and
-- | enums one for the packed encoding too.
fieldBranches :: Array String -> InMessage -> Array (Array String)
fieldBranches names { field, into } = case field.shape of
  Repeated _ -> case packedReadingOf field.value of
    Just packed -> [ single, packedBranch field.number packed (\values -> loopWith values) field.variable ]
    Nothing -> [ single ]
  MapOf entry -> [ entryBranch field.number entry.reader (\value -> loopWith (updateFor field value)) ]
  Implicit -> [ single ]
  Required -> [ single ]
  Optional -> [ single ]
  InOneof -> [ single ]
  where
  loopWith value = "loop next " <> String.joinWith " " (map (\name -> if name == into then value else name) names)
  single = singleBranch field.number field.value (\value -> loopWith (updateFor field value))

-- | How the decoder reads a value: at a position, as text, as bytes, or with a message's reader.
data Reading
  = AtPosition String (String -> String)
  | Text
  | Raw
  | Nested String

readingOf :: ValueType -> Reading
readingOf = case _ of
  Int32Value -> varint "Wire.varint32"
  Int64Value -> varint "Wire.varint64"
  UInt32Value -> varint "Wire.uint32"
  UInt64Value -> varint "Wire.uint64"
  SInt32Value -> varint "Wire.sint32"
  SInt64Value -> varint "Wire.sint64"
  BoolValue -> varint "Wire.bool"
  EnumValue reference -> AtPosition varintEnd \position -> "(" <> reference.qualifier <> "to" <> reference.name <> " (Wire.varint32 input " <> position <> "))"
  Fixed32Value -> fixed 4 "Wire.unsignedFixed32"
  SFixed32Value -> fixed 4 "Wire.fixed32"
  FloatValue -> fixed 4 "Wire.float"
  Fixed64Value -> fixed 8 "Wire.unsignedFixed64"
  SFixed64Value -> fixed 8 "Wire.fixed64"
  DoubleValue -> fixed 8 "Wire.double"
  StringValue -> Text
  BytesValue -> Raw
  MessageValue reference -> Nested (reference.qualifier <> "read" <> reference.name)
  where
  varintEnd = "Wire.varintEnd input afterTag end"
  varint read = AtPosition varintEnd \position -> "(" <> read <> " input " <> position <> ")"
  fixed width read = AtPosition ("Wire.fixedEnd afterTag " <> show width <> " end") \position -> "(" <> read <> " input " <> position <> ")"

singleBranch :: Int -> ValueType -> (String -> String) -> Array String
singleBranch number value continue = case readingOf value of
  AtPosition nextAt read ->
    [ tag
    , "  let next = " <> nextAt
    , "  if next < 0 then Left (failure next afterTag)"
    , "  else " <> continue (read "afterTag")
    ]
  Text ->
    delimited
      <>
        [ "  else do"
        , "    let text = Wire.string input payload next"
        , "    if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)"
        , "    else " <> continue "text"
        ]
  Raw -> delimited <> [ "  else " <> continue "(Wire.bytes input payload next)" ]
  Nested read ->
    delimited
      <>
        [ "  else case runFn3 " <> read <> " input payload next of"
        , "    Left error -> Left error"
        , "    Right decoded -> " <> continue "decoded"
        ]
  where
  tag = show (tagOf number (wireTypeOf value)) <> " -> do"
  delimited =
    [ tag
    , "  let payload = Wire.varintEnd input afterTag end"
    , "  let next = Wire.delimitedEnd input afterTag payload end"
    , "  if next < 0 then Left (failure next afterTag)"
    ]

-- | A branch for a map field's entries, read with the entry's reader.
entryBranch :: Int -> String -> (String -> String) -> Array String
entryBranch number read continue =
  [ show (tagOf number LengthDelimited) <> " -> do"
  , "  let payload = Wire.varintEnd input afterTag end"
  , "  let next = Wire.delimitedEnd input afterTag payload end"
  , "  if next < 0 then Left (failure next afterTag)"
  , "  else case runFn3 " <> read <> " input payload next of"
  , "    Left error -> Left error"
  , "    Right decoded -> " <> continue "decoded"
  ]

-- | How the decoder reads a packed field: varints with a function, or values of a width.
data PackedReading
  = PackedVarints String
  | PackedFixed Int String

-- | How to read a repeated field of this type packed, if it can be packed.
packedReadingOf :: ValueType -> Maybe PackedReading
packedReadingOf = case _ of
  Int32Value -> Just (PackedVarints "packedInt32")
  Int64Value -> varints "Wire.varint64"
  UInt64Value -> varints "Wire.uint64"
  UInt32Value -> varints "Wire.uint32"
  SInt32Value -> varints "Wire.sint32"
  SInt64Value -> varints "Wire.sint64"
  BoolValue -> varints "Wire.bool"
  EnumValue reference -> varints ("(\\bytes at -> " <> reference.qualifier <> "to" <> reference.name <> " (Wire.varint32 bytes at))")
  Fixed32Value -> Just (PackedFixed 4 "Wire.unsignedFixed32")
  SFixed32Value -> Just (PackedFixed 4 "Wire.fixed32")
  FloatValue -> Just (PackedFixed 4 "Wire.float")
  Fixed64Value -> Just (PackedFixed 8 "Wire.unsignedFixed64")
  SFixed64Value -> Just (PackedFixed 8 "Wire.fixed64")
  DoubleValue -> Just (PackedFixed 8 "Wire.double")
  StringValue -> Nothing
  BytesValue -> Nothing
  MessageValue _ -> Nothing
  where
  varints read = Just (PackedVarints ("Decode.packedVarints " <> read))

packedBranch :: Int -> PackedReading -> (String -> String) -> String -> Array String
packedBranch number packed continue values =
  [ show (tagOf number LengthDelimited) <> " -> do"
  , "  let payload = Wire.varintEnd input afterTag end"
  , "  let next = Wire.delimitedEnd input afterTag payload end"
  , "  if next < 0 then Left (failure next afterTag)"
  ]
    <> case packed of
      PackedVarints read ->
        [ "  else if not (Wire.packedVarintsValid input payload next) then Left (MalformedVarint payload)"
        , "  else " <> continue ("(" <> read <> " input payload next " <> values <> ")")
        ]
      PackedFixed width read ->
        [ "  else if not (Wire.packedFixedValid payload next " <> show width <> ") then Left (Truncated payload)"
        , "  else " <> continue ("(Decode.packedFixed " <> show width <> " " <> read <> " input payload next " <> values <> ")")
        ]

-- Decoding in two steps

-- | Whether the message has enough fields to read them in two steps, and they're all plain
-- | values with numbers small enough to index an array by.
twoStep :: Int -> MessageModel -> Boolean
twoStep fieldsThreshold message =
  Array.length message.members >= fieldsThreshold
    && all plainValue message.members
    && fromMaybe 0 (maximum (map _.field.number (fieldsOf message))) <= 256
  where
  plainValue = case _ of
    Plain field -> case field.shape of
      Implicit -> isJust (fromFields field)
      Required -> false
      Optional -> false
      Repeated _ -> false
      MapOf _ -> false
      InOneof -> false
    Oneof _ -> false

fieldsReader :: MessageModel -> Array String
fieldsReader message =
  [ "read" <> message.name <> " :: Reader " <> message.name
  , "read" <> message.name <> " = mkFn3 \\input start end -> do"
  , "  let"
  , "    scan position fields"
  , "      | position >= end = Right fields"
  , "      | otherwise = do"
  , "          let afterTag = Wire.varintEnd input position end"
  , "          if afterTag < 0 then Left (failure afterTag position)"
  , "          else do"
  , "            let tag = Wire.varint32 input position"
  , "            let next = Wire.skip input tag afterTag end"
  , "            if next < 0 then Left (failure next afterTag)"
  , "            else scan next (Fields.note fields " <> wireTypesName <> " tag afterTag)"
  , "  case scan start (Fields.new input " <> show (largest + 1) <> ") of"
  , "    Left error -> Left error"
  , "    Right fields -> do"
  , "      let"
  , "        record ="
  ]
    <> indentBy 10 (recordLines (map (\{ field } -> field.label <> ": " <> fromMaybe "" (fromFields field)) fields))
    <> indentBy 6 checks
    <> [ ""
       , wireTypesName <> " :: Array Int"
       , wireTypesName <> " = [ " <> String.joinWith ", " (map wireTypeAt (Array.range 0 largest)) <> " ]"
       ]
  where
  fields = fieldsOf message
  largest = fromMaybe 0 (maximum (map _.field.number fields))
  wireTypesName = lowerFirst message.name <> "WireTypes"
  wireTypeAt number = case Array.find (\{ field } -> field.number == number) fields of
    Just { field } -> show (wireNumber (wireTypeOf field.value))
    Nothing -> "-1"
  strings = Array.filter (\{ field } -> field.value == StringValue) fields
  result = if message.recursive then "Right (" <> message.name <> " record)" else "Right record"
  checks = case strings of
    [] -> [ result ]
    _ ->
      Array.mapWithIndex (\index { field } -> (if index == 0 then "if " else "else if ") <> "record." <> field.label <> " == Wire.invalidUtf8 then Left (InvalidUtf8 (Fields.payloadStart input fields " <> show field.number <> " end))") strings
        <> [ "else " <> result ]

-- | Reads the field from where the first step noted it is, unless it's a message.
fromFields :: Field -> Maybe String
fromFields field = case field.value of
  Int32Value -> Just int32
  SFixed32Value -> Just fixed32
  SInt32Value -> Just ("Wire.zigzag32 (" <> int32 <> ")")
  UInt32Value -> Just ("UInt32 (" <> int32 <> ")")
  EnumValue reference -> Just (reference.qualifier <> "to" <> reference.name <> " (" <> int32 <> ")")
  Int64Value -> Just int64
  SFixed64Value -> Just fixed64
  SInt64Value -> Just ("Wire.zigzag64 (" <> int64 <> ")")
  UInt64Value -> Just ("UInt64 (" <> int64 <> ")")
  Fixed32Value -> Just ("UInt32 (" <> fixed32 <> ")")
  Fixed64Value -> Just ("UInt64 (" <> fixed64 <> ")")
  BoolValue -> Just ("runFn3 Fields.bool input fields " <> number)
  DoubleValue -> Just ("runFn3 Fields.double input fields " <> number)
  FloatValue -> Just ("runFn3 Fields.float input fields " <> number)
  StringValue -> Just ("runFn4 Fields.string input fields " <> number <> " end")
  BytesValue -> Just ("runFn4 Fields.bytes input fields " <> number <> " end")
  MessageValue _ -> Nothing
  where
  number = show field.number
  int32 = "runFn3 Fields.int32 input fields " <> number
  int64 = "runFn3 Fields.int64 input fields " <> number
  fixed32 = "runFn3 Fields.fixed32 input fields " <> number
  fixed64 = "runFn3 Fields.fixed64 input fields " <> number
