-- | What the generator needs to know about the files it generates modules for, worked out from
-- | the descriptors protoc sends: PureScript names for everything, which messages refer to
-- | themselves, and the shape of each field.
module Yoga.Protobuf.Plugin.Schema
  ( Schema
  , FileModel
  , MessageModel
  , EnumModel
  , Member(..)
  , Field
  , Shape(..)
  , ValueType(..)
  , Reference
  , MapEntry
  , Import
  , schemaOf
  , packable
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..), note)
import Data.Foldable (any, foldl)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust, maybe)
import Data.Newtype (un)
import Data.Set (Set)
import Data.Set as Set
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Data.Traversable (traverse)
import Data.Tuple.Nested ((/\))
import Yoga.Protobuf.Plugin.Google.Protobuf.Descriptor (DescriptorProto(..), EnumDescriptorProto, FieldDescriptorProto, FieldDescriptorProto_Type(..), FileDescriptorProto)
import Yoga.Protobuf.Plugin.Google.Protobuf.Descriptor as Descriptor
import Yoga.Protobuf.Plugin.Names as Names

type Schema = Array FileModel

type FileModel =
  { protoName :: String
  , moduleName :: String
  , imports :: Array Import
  , messages :: Array MessageModel
  , enums :: Array EnumModel
  }

type Import = { moduleName :: String, alias :: String }

type MessageModel =
  { name :: String
  , recursive :: Boolean
  , members :: Array Member
  , entries :: Array MapEntry
  }

-- | A field of the record: one protocol buffer field, or all the fields of a `oneof`.
data Member
  = Plain Field
  | Oneof { label :: String, variable :: String, fields :: Array Field }

type Field =
  { label :: String
  , variable :: String
  , number :: Int
  , value :: ValueType
  , shape :: Shape
  }

data Shape
  -- | proto3 without `optional`: the value, which is left out when it's the default.
  = Implicit
  -- | proto2 `required`: the value, always written.
  | Required
  -- | Explicit presence, `optional` and message fields: `Maybe` the value.
  | Optional
  -- | `repeated`, written packed or not.
  | Repeated Boolean
  | MapOf MapEntry
  -- | One of the fields of a `oneof`.
  | InOneof

type MapEntry = { reader :: String, key :: ValueType, value :: ValueType }

data ValueType
  = DoubleValue
  | FloatValue
  | Int64Value
  | UInt64Value
  | Int32Value
  | Fixed64Value
  | Fixed32Value
  | BoolValue
  | StringValue
  | BytesValue
  | UInt32Value
  | SFixed32Value
  | SFixed64Value
  | SInt32Value
  | SInt64Value
  | MessageValue Reference
  | EnumValue Reference

derive instance Eq ValueType

-- | A message or enum type as the generated module refers to it: `qualifier` is empty or the
-- | alias of the module it's from, with a dot. `zero` is the first constructor of an enum.
type Reference = { qualifier :: String, name :: String, recursive :: Boolean, zero :: String }

type EnumModel =
  { name :: String
  , constructors :: Array { constructor :: String, number :: Int }
  , unrecognized :: String
  }

-- | Whether a repeated field of this type can be packed: numbers, booleans and enums.
packable :: ValueType -> Boolean
packable = case _ of
  StringValue -> false
  BytesValue -> false
  MessageValue _ -> false
  _ -> true

-- | The models of the files to generate, under the module prefix.
schemaOf :: String -> Array String -> Array FileDescriptorProto -> Either String Schema
schemaOf prefix toGenerate files = traverse (fileModel symbols prefix) generated
  where
  symbols = symbolTable prefix files
  generated = Array.filter (\file -> Array.elem (nameOf file) toGenerate) files
  nameOf file = fromMaybe "" file.name

-- | Everything about a message or enum type that a file referring to it needs.
type Declaration =
  { moduleName :: String
  , name :: String
  , recursive :: Boolean
  , mapEntry :: Maybe { key :: FieldDescriptorProto, value :: FieldDescriptorProto }
  , constructors :: Array String
  , zero :: String
  }

type Symbols = Map String Declaration

-- | A message or enum found walking a file, with its fully qualified protocol buffer name
-- | (`.google.protobuf.DescriptorProto`) and the names it's nested in.
type Found a = { fullName :: String, nesting :: Array String, descriptor :: a }

symbolTable :: String -> Array FileDescriptorProto -> Symbols
symbolTable prefix files = Map.fromFoldable (Array.concatMap symbolsOf files)
  where
  recursiveMessages = recursive files
  symbolsOf file = do
    let module_ = moduleOf prefix file
    let newtypes = map (Names.typeName <<< _.nesting) (Array.filter (\found -> Set.member found.fullName recursiveMessages) (messagesOf file))
    let enumNames = enumConstructors newtypes (enumsOf file)
    map (messageSymbol module_) (messagesOf file) <> map (enumSymbol module_ enumNames) (enumsOf file)
  messageSymbol module_ found = do
    let message = un DescriptorProto found.descriptor
    found.fullName /\
      { moduleName: module_
      , name: Names.typeName found.nesting
      , recursive: Set.member found.fullName recursiveMessages
      , mapEntry: mapEntryOf message
      , constructors: []
      , zero: ""
      }
  enumSymbol module_ enumNames found = do
    let constructors = fromMaybe [] (Map.lookup found.fullName enumNames)
    found.fullName /\
      { moduleName: module_
      , name: Names.typeName found.nesting
      , recursive: false
      , mapEntry: Nothing
      , constructors
      , zero: fromMaybe "" (Array.head constructors)
      }
  mapEntryOf message
    | (message.options >>= _.mapEntry) == Just true = do
        key <- Array.find (\field -> field.number == Just 1) message.field
        value <- Array.find (\field -> field.number == Just 2) message.field
        pure { key, value }
    | otherwise = Nothing

moduleOf :: String -> FileDescriptorProto -> String
moduleOf prefix file = Names.moduleName prefix (fromMaybe "" file.package) (fromMaybe "" file.name)

messagesOf :: FileDescriptorProto -> Array (Found DescriptorProto)
messagesOf file = Array.concatMap (walk (packagePrefix file) []) file.messageType
  where
  walk scope nesting message = do
    let record = un DescriptorProto message
    let name = fromMaybe "" record.name
    let found = { fullName: scope <> "." <> name, nesting: Array.snoc nesting name, descriptor: message }
    [ found ] <> Array.concatMap (walk found.fullName found.nesting) record.nestedType

enumsOf :: FileDescriptorProto -> Array (Found EnumDescriptorProto)
enumsOf file = map (top (packagePrefix file)) file.enumType <> Array.concatMap nested (messagesOf file)
  where
  top scope enum = found scope [] enum
  nested message = map (found message.fullName message.nesting) (un DescriptorProto message.descriptor).enumType
  found scope nesting enum = do
    let name = fromMaybe "" enum.name
    { fullName: scope <> "." <> name, nesting: Array.snoc nesting name, descriptor: enum }

packagePrefix :: FileDescriptorProto -> String
packagePrefix file = case file.package of
  Just package | package /= "" -> "." <> package
  _ -> ""

-- | The messages that refer to themselves, through any number of fields of any kind. They become
-- | newtypes, as a type synonym can't refer to itself.
recursive :: Array FileDescriptorProto -> Set String
recursive files = Set.fromFoldable (Array.filter reachesItself (Array.fromFoldable (Map.keys edges)))
  where
  edges = Map.fromFoldable (map (\found -> found.fullName /\ referencesOf found.descriptor) (Array.concatMap messagesOf files))
  referencesOf message = Array.mapMaybe messageType (un DescriptorProto message).field
  messageType field
    | field.type == Just TypeMessage || field.type == Just TypeGroup = field.typeName
    | otherwise = Nothing
  successors name = fromMaybe [] (Map.lookup name edges)
  reachesItself name = search name Set.empty (successors name)
  search target seen stack = case Array.uncons stack of
    Nothing -> false
    Just { head, tail }
      | head == target -> true
      | Set.member head seen -> search target seen tail
      | otherwise -> search target (Set.insert head seen) (successors head <> tail)

-- | The constructors of each enum in a module, by the enum's full name. A value's constructor is
-- | its name in Pascal case, without the prefix all values share if they follow the style guide
-- | (`TYPE_DOUBLE` in `Type` is `Double`). Enums whose constructors would clash with another's
-- | get their name in front, and if they still clash, their full type name. Nor may they clash
-- | with the constructors of the module's newtypes, or with `Maybe`'s and `Either`'s.
enumConstructors :: Array String -> Array (Found EnumDescriptorProto) -> Map String (Array String)
enumConstructors newtypes enums = settle (map (const 0) indexes)
  where
  indexes = Array.range 0 (Array.length enums - 1)
  settle levels = do
    let names = Array.zipWith namesAt enums levels
    let clashing = Array.filter (clashes names) indexes
    if Array.null clashing then Map.fromFoldable (Array.zipWith (\found constructors -> found.fullName /\ constructors) enums names)
    else settle (Array.mapWithIndex (\index level -> if Array.elem index clashing && level < 2 then level + 1 else level) levels)
  clashes names index = do
    let own = fromMaybe [] (Array.index names index)
    let others = Array.concat (Array.mapMaybe (\other -> if other == index then Nothing else Array.index names other) indexes)
    any (\name -> Array.elem name others || Array.elem name reserved) own
      || Array.length (Array.nub own) /= Array.length own
  reserved = [ "Just", "Nothing", "Left", "Right" ] <> newtypes
  namesAt found level = map (constructorAt found level) found.descriptor.value
  constructorAt found level value = do
    let enumName = fromMaybe "" found.descriptor.name
    let valueName = fromMaybe "" value.name
    let stripped = Names.pascalCase (strip found.descriptor valueName)
    let full = Names.pascalCase valueName
    case level of
      0 -> stripped
      1 -> if String.indexOf (Pattern (Names.upperFirst enumName)) full == Just 0 then full else Names.upperFirst enumName <> stripped
      _ -> Names.typeName found.nesting <> stripped
  strip enum valueName = do
    let prefix = Names.enumPrefix (fromMaybe "" enum.name)
    let values = map (fromMaybe "" <<< _.name) enum.value
    if all (strippable prefix) values then fromMaybe valueName (String.stripPrefix (Pattern prefix) valueName)
    else valueName
  strippable prefix valueName = case String.stripPrefix (Pattern prefix) valueName of
    Just rest -> startsWithLetter rest
    Nothing -> false
  startsWithLetter rest = case String.codePointAt 0 rest of
    Just first -> do
      let character = String.singleton first
      (character >= "A" && character <= "Z") || (character >= "a" && character <= "z")
    Nothing -> false
  all predicate values = not (any (not <<< predicate) values)

fileModel :: Symbols -> String -> FileDescriptorProto -> Either String FileModel
fileModel symbols prefix file = do
  when (file.syntax == Just "editions") (Left (fileName <> ": editions aren't supported yet"))
  messages <- traverse (messageModel symbols module_ imports proto3) (Array.filter (not <<< isMapEntry) (messagesOf file))
  pure
    { protoName: fileName
    , moduleName: module_
    , imports
    , messages
    , enums: map (enumModel symbols) (enumsOf file)
    }
  where
  fileName = fromMaybe "" file.name
  module_ = moduleOf prefix file
  imports = importsOf symbols module_ (messagesOf file)
  proto3 = file.syntax == Just "proto3"
  isMapEntry found = isJust (Map.lookup found.fullName symbols >>= _.mapEntry)

-- | The modules the file's fields refer to, each under the shortest alias that's free.
importsOf :: Symbols -> String -> Array (Found DescriptorProto) -> Array Import
importsOf symbols module_ messages = foldl add [] (Array.nub (Array.mapMaybe otherModule fields))
  where
  fields = Array.concatMap (\found -> (un DescriptorProto found.descriptor).field) messages
  otherModule field = do
    typeName <- field.typeName
    symbol <- Map.lookup typeName symbols
    if symbol.moduleName == module_ then Nothing else Just symbol.moduleName
  add imports moduleName = Array.snoc imports { moduleName, alias: aliasFor imports moduleName }
  aliasFor imports moduleName = do
    let segments = String.split (Pattern ".") moduleName
    let candidates = map (\count -> String.joinWith "" (Array.drop (Array.length segments - count) segments)) (Array.range 1 (Array.length segments))
    let taken = map _.alias imports <> fixedAliases
    fromMaybe (String.joinWith "" segments) (Array.find (\alias -> not (Array.elem alias taken)) candidates)
  fixedAliases = [ "Array", "Bytes", "Codec", "Decode", "Fields", "Int64", "Map", "Repeated", "Variant", "Wire", "Writer" ]

aliasOf :: Array Import -> String -> String
aliasOf imports moduleName = maybe "" (\found -> found.alias <> ".") (Array.find (\entry -> entry.moduleName == moduleName) imports)

messageModel :: Symbols -> String -> Array Import -> Boolean -> Found DescriptorProto -> Either String MessageModel
messageModel symbols module_ imports proto3 found = do
  fields <- traverse (fieldModel symbols module_ imports proto3) message.field
  let entries = Array.mapMaybe mapEntryOf fields
  pure
    { name: symbol.name
    , recursive: symbol.recursive
    , members: membersOf fields
    , entries
    }
  where
  message = un DescriptorProto found.descriptor
  symbol = fromMaybe noSymbol (Map.lookup found.fullName symbols)
  mapEntryOf field = case field.shape of
    MapOf entry -> Just entry
    _ -> Nothing
  oneofs = map (\oneof -> Names.recordLabel (fromMaybe "" oneof.name)) message.oneofDecl
  realOneof field = case field.oneofIndex of
    Just index | field.proto3Optional /= Just true -> Array.index oneofs index
    _ -> Nothing
  membersOf fields = foldl (addMember fields) [] (Array.zip message.field fields)
  addMember fields members (descriptor /\ field) = case realOneof descriptor of
    Nothing -> Array.snoc members (Plain field)
    Just label
      | any (isOneof label) members -> members
      | otherwise -> Array.snoc members (Oneof { label, variable: Names.variable label, fields: map (\(_ /\ member) -> member) (Array.filter (\(other /\ _) -> realOneof other == Just label) (Array.zip message.field fields)) })
  isOneof label = case _ of
    Oneof oneof -> oneof.label == label
    Plain _ -> false

fieldModel :: Symbols -> String -> Array Import -> Boolean -> FieldDescriptorProto -> Either String Field
fieldModel symbols module_ imports proto3 field = do
  value <- valueTypeOf symbols module_ imports field
  shape <- shapeOf value
  pure { label, variable: Names.variable label, number: fromMaybe 0 field.number, value, shape }
  where
  label = Names.recordLabel (fromMaybe "" field.name)
  shapeOf value
    | field.label == Just Descriptor.Repeated = case mapEntry of
        Just entry -> map MapOf (mapEntryModel entry)
        Nothing -> Right (Repeated (packable value && packed))
    | field.label == Just Descriptor.Required = Right Required
    | field.proto3Optional == Just true = Right Optional
    | isJust field.oneofIndex = Right InOneof
    | otherwise = case value of
        MessageValue _ -> Right Optional
        _ -> Right (if proto3 then Implicit else Optional)
  packed = case field.options >>= _.packed of
    Just explicit -> explicit
    Nothing -> proto3
  mapEntry = field.typeName >>= \typeName -> Map.lookup typeName symbols >>= _.mapEntry
  mapEntryModel entry = do
    key <- valueTypeOf symbols module_ imports entry.key
    value <- valueTypeOf symbols module_ imports entry.value
    let entryName = maybe "" _.name (field.typeName >>= \typeName -> Map.lookup typeName symbols)
    pure { reader: "read" <> entryName, key, value }

valueTypeOf :: Symbols -> String -> Array Import -> FieldDescriptorProto -> Either String ValueType
valueTypeOf symbols module_ imports field = case field.type of
  Just TypeDouble -> Right DoubleValue
  Just TypeFloat -> Right FloatValue
  Just TypeInt64 -> Right Int64Value
  Just TypeUint64 -> Right UInt64Value
  Just TypeInt32 -> Right Int32Value
  Just TypeFixed64 -> Right Fixed64Value
  Just TypeFixed32 -> Right Fixed32Value
  Just TypeBool -> Right BoolValue
  Just TypeString -> Right StringValue
  Just TypeBytes -> Right BytesValue
  Just TypeUint32 -> Right UInt32Value
  Just TypeSfixed32 -> Right SFixed32Value
  Just TypeSfixed64 -> Right SFixed64Value
  Just TypeSint32 -> Right SInt32Value
  Just TypeSint64 -> Right SInt64Value
  Just TypeMessage -> map MessageValue reference
  Just TypeEnum -> map EnumValue reference
  Just TypeGroup -> Left (fieldName <> ": groups aren't supported yet")
  _ -> Left (fieldName <> ": unknown field type")
  where
  fieldName = fromMaybe "" field.name
  reference = do
    typeName <- note (fieldName <> ": no type name") field.typeName
    symbol <- note (fieldName <> ": unknown type " <> typeName) (Map.lookup typeName symbols)
    pure
      { qualifier: if symbol.moduleName == module_ then "" else aliasOf imports symbol.moduleName
      , name: symbol.name
      , recursive: symbol.recursive
      , zero: symbol.zero
      }

enumModel :: Symbols -> Found EnumDescriptorProto -> EnumModel
enumModel symbols found =
  { name: symbol.name
  , constructors: Array.zipWith (\constructor value -> { constructor, number: fromMaybe 0 value.number }) symbol.constructors found.descriptor.value
  , unrecognized: symbol.name <> "Unrecognized"
  }
  where
  symbol = fromMaybe noSymbol (Map.lookup found.fullName symbols)

noSymbol :: Declaration
noSymbol = { moduleName: "", name: "", recursive: false, mapEntry: Nothing, constructors: [], zero: "" }
