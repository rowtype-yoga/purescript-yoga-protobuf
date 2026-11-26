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
  , Packing(..)
  , ValueType(..)
  , GeneratorError(..)
  , describe
  , Reference
  , MapEntry
  , Import
  , ServiceModel
  , MethodModel
  , Streaming(..)
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
import Data.Traversable (sequence, traverse)
import Data.Tuple.Nested ((/\))

import Yoga.Protobuf.Plugin.Google.Protobuf.Descriptor (DescriptorProto(..), EnumDescriptorProto, FieldDescriptorProto, FieldDescriptorProto_Type(..), FileDescriptorProto, MethodDescriptorProto, ServiceDescriptorProto)
import Yoga.Protobuf.Plugin.Google.Protobuf.Descriptor as Descriptor
import Yoga.Protobuf.Plugin.Names as Names

-- | The files to generate modules for.
type Schema = Array FileModel

-- | Why the generator can't generate a module for a file, which protoc shows the user.
data GeneratorError
  = EditionsUnsupported String
  | GroupsUnsupported String
  | UnknownFieldType String
  | MissingTypeName String
  | UnknownType String String

derive instance Eq GeneratorError

instance Show GeneratorError where
  show error = "(GeneratorError " <> show (describe error) <> ")"

-- | The error as protoc-gen-purescript reports it.
describe :: GeneratorError -> String
describe = case _ of
  EditionsUnsupported file -> file <> ": editions aren't supported yet"
  GroupsUnsupported field -> field <> ": groups aren't supported yet"
  UnknownFieldType field -> field <> ": unknown field type"
  MissingTypeName field -> field <> ": no type name"
  UnknownType field typeName -> field <> ": unknown type " <> typeName

-- | A `.proto` file and the module it becomes.
type FileModel =
  { protoName :: String
  , moduleName :: String
  , proto3 :: Boolean
  , imports :: Array Import
  , messages :: Array MessageModel
  , enums :: Array EnumModel
  , services :: Array ServiceModel
  }

-- | A service: `typeName` is the row of its methods, `valueName` the value with their routes and
-- | codecs. `comment` is what the `.proto` says above it.
type ServiceModel =
  { fullName :: String
  , comment :: Maybe String
  , typeName :: String
  , valueName :: String
  , methods :: Array MethodModel
  }

-- | A method: its record `label`, its route, `/greeter.v1.Greeter/SayHello`, and its messages.
type MethodModel =
  { label :: String
  , name :: String
  , comment :: Maybe String
  , procedure :: String
  , streaming :: Streaming
  , request :: Reference
  , response :: Reference
  }

-- | Which sides of a method send a stream.
data Streaming = NoStreams | ServerStreams | ClientStreams | BothStreams

derive instance Eq Streaming

-- | Another generated module this one refers to, and its alias.
type Import = { moduleName :: String, alias :: String }

-- | A message: `fullName` is its protocol buffer name, `name` its PureScript type's. A message
-- | that refers to itself is `recursive`, and becomes a newtype.
type MessageModel =
  { fullName :: String
  , comment :: Maybe String
  , name :: String
  , recursive :: Boolean
  , members :: Array Member
  , entries :: Array MapEntry
  }

-- | A field of the record: one protocol buffer field, or all the fields of a `oneof`.
data Member
  = Plain Field
  | Oneof { label :: String, variable :: String, fields :: Array Field }

-- | A field: its record `label`, the decoder's local `variable` for it, which isn't a keyword,
-- | and whether the `.proto` says `optional`.
type Field =
  { label :: String
  , variable :: String
  , number :: Int
  , declaredOptional :: Boolean
  , value :: ValueType
  , shape :: Shape
  }

-- | How a field holds its value.
data Shape
  -- | proto3 without `optional`: the value, which is left out when it's the default.
  = Implicit
  -- | proto2 `required`: the value, always written.
  | Required
  -- | Explicit presence, `optional` and message fields: `Maybe` the value.
  | Optional
  | Repeated Packing
  | MapOf MapEntry
  -- | One of the fields of a `oneof`.
  | InOneof

-- | How a repeated field is written. Decoders read both.
data Packing = Packed | Expanded

derive instance Eq Packing

-- | A `map<k, v>` field's entries, which the decoder reads with `reader`, and the name protoc
-- | gives their message, `LabelsEntry`.
type MapEntry = { reader :: String, protoName :: String, key :: ValueType, value :: ValueType }

-- | The protocol buffer type of a value.
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
-- | `fullName` is its protocol buffer name, `ticker.v1.Quote`.
type Reference = { qualifier :: String, name :: String, fullName :: String, recursive :: Boolean, zero :: String }

-- | An enum, with its constructors in the order of its values and the one for numbers it
-- | doesn't know.
type EnumModel =
  { fullName :: String
  , comment :: Maybe String
  , name :: String
  , constructors :: Array { constructor :: String, number :: Int }
  , unrecognized :: String
  }

-- | Whether a repeated field of this type can be packed: numbers, booleans and enums.
packable :: ValueType -> Boolean
packable = case _ of
  DoubleValue -> true
  FloatValue -> true
  Int64Value -> true
  UInt64Value -> true
  Int32Value -> true
  Fixed64Value -> true
  Fixed32Value -> true
  BoolValue -> true
  UInt32Value -> true
  SFixed32Value -> true
  SFixed64Value -> true
  SInt32Value -> true
  SInt64Value -> true
  EnumValue _ -> true
  StringValue -> false
  BytesValue -> false
  MessageValue _ -> false

-- | The models of the files to generate, under the module prefix.
schemaOf :: String -> Array String -> Array FileDescriptorProto -> Either GeneratorError Schema
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
-- | (`.google.protobuf.DescriptorProto`), the names it's nested in, and its `path` in the file's
-- | source code info, which is where its comments are.
type Found a = { fullName :: String, nesting :: Array String, path :: Array Int, descriptor :: a }

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
messagesOf file = Array.concat (Array.mapWithIndex (walk (packagePrefix file) [] [ messageTypeField ]) file.messageType)
  where
  walk scope nesting within index message = do
    let record = un DescriptorProto message
    let name = fromMaybe "" record.name
    let found = { fullName: scope <> "." <> name, nesting: Array.snoc nesting name, path: within <> [ index ], descriptor: message }
    [ found ] <> Array.concat (Array.mapWithIndex (walk found.fullName found.nesting (found.path <> [ nestedTypeField ])) record.nestedType)
  messageTypeField = 4
  nestedTypeField = 3

enumsOf :: FileDescriptorProto -> Array (Found EnumDescriptorProto)
enumsOf file = Array.mapWithIndex top file.enumType <> Array.concatMap nested (messagesOf file)
  where
  top index enum = found (packagePrefix file) [] [ enumTypeField, index ] enum
  nested message = Array.mapWithIndex (\index enum -> found message.fullName message.nesting (message.path <> [ nestedEnumField, index ]) enum) (un DescriptorProto message.descriptor).enumType
  found scope nesting path enum = do
    let name = fromMaybe "" enum.name
    { fullName: scope <> "." <> name, nesting: Array.snoc nesting name, path, descriptor: enum }
  enumTypeField = 5
  nestedEnumField = 4

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

fileModel :: Symbols -> String -> FileDescriptorProto -> Either GeneratorError FileModel
fileModel symbols prefix file = do
  when (file.syntax == Just "editions") (Left (EditionsUnsupported fileName))
  messages <- traverse (messageModel symbols comments module_ imports proto3) (Array.filter (not <<< isMapEntry) (messagesOf file))
  services <- sequence (Array.mapWithIndex (serviceModel symbols comments module_ imports taken (packagePrefix file)) file.service)
  pure
    { protoName: fileName
    , moduleName: module_
    , proto3
    , imports
    , messages
    , enums
    , services
    }
  where
  fileName = fromMaybe "" file.name
  module_ = moduleOf prefix file
  enums = map (enumModel symbols comments) (enumsOf file)
  comments = commentsOf file
  taken = map (Names.typeName <<< _.nesting) (messagesOf file) <> map _.name enums
  imports = importsOf symbols module_ (messagesOf file) (Array.concatMap methodTypes file.service)
  methodTypes serviceDescriptor = Array.concatMap (\method -> Array.catMaybes [ method.inputType, method.outputType ]) serviceDescriptor.method
  proto3 = file.syntax == Just "proto3"
  isMapEntry found = isJust (Map.lookup found.fullName symbols >>= _.mapEntry)

-- | The modules the file's fields refer to, each under the shortest alias that's free.
importsOf :: Symbols -> String -> Array (Found DescriptorProto) -> Array String -> Array Import
importsOf symbols module_ messages methodTypes = foldl add [] (Array.nub (Array.mapMaybe otherModule typeNames))
  where
  fields = Array.concatMap (\found -> (un DescriptorProto found.descriptor).field) messages
  typeNames = Array.mapMaybe _.typeName fields <> methodTypes
  otherModule typeName = do
    symbol <- Map.lookup typeName symbols
    if symbol.moduleName == module_ then Nothing else Just symbol.moduleName
  add imports moduleName = Array.snoc imports { moduleName, alias: aliasFor imports moduleName }
  aliasFor imports moduleName = do
    let segments = String.split (Pattern ".") moduleName
    let candidates = map (\count -> String.joinWith "" (Array.drop (Array.length segments - count) segments)) (Array.range 1 (Array.length segments))
    let taken = map _.alias imports <> fixedAliases
    fromMaybe (String.joinWith "" segments) (Array.find (\alias -> not (Array.elem alias taken)) candidates)
  fixedAliases = [ "Array", "Bytes", "Codec", "Connect", "Decode", "Fields", "Int64", "Map", "Repeated", "Variant", "Wire", "Writer" ]

-- | The comment above each thing in the file, by its path in the source code info.
type Comments = Map (Array Int) String

commentsOf :: FileDescriptorProto -> Comments
commentsOf file = Map.fromFoldable (Array.mapMaybe commented (maybe [] _.location file.sourceCodeInfo))
  where
  commented location = location.leadingComments <#> \comment -> location.path /\ comment

aliasOf :: Array Import -> String -> String
aliasOf imports moduleName = maybe "" (\found -> found.alias <> ".") (Array.find (\entry -> entry.moduleName == moduleName) imports)

messageModel :: Symbols -> Comments -> String -> Array Import -> Boolean -> Found DescriptorProto -> Either GeneratorError MessageModel
messageModel symbols comments module_ imports proto3 found = do
  fields <- traverse (fieldModel symbols module_ imports proto3) message.field
  pure
    { fullName: String.drop 1 found.fullName
    , comment: Map.lookup found.path comments
    , name: symbol.name
    , recursive: symbol.recursive
    , members: membersOf fields
    , entries: Array.mapMaybe mapEntryOf fields
    }
  where
  message = un DescriptorProto found.descriptor
  symbol = fromMaybe noSymbol (Map.lookup found.fullName symbols)
  mapEntryOf field = case field.shape of
    MapOf entry -> Just entry
    Implicit -> Nothing
    Required -> Nothing
    Optional -> Nothing
    Repeated _ -> Nothing
    InOneof -> Nothing
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

fieldModel :: Symbols -> String -> Array Import -> Boolean -> FieldDescriptorProto -> Either GeneratorError Field
fieldModel symbols module_ imports proto3 field = do
  value <- valueTypeOf symbols module_ imports field
  shape <- shapeOf value
  pure { label, variable: Names.variable label, number: fromMaybe 0 field.number, declaredOptional: field.proto3Optional == Just true, value, shape }
  where
  label = Names.recordLabel (fromMaybe "" field.name)
  shapeOf value
    | field.label == Just Descriptor.Repeated = case mapEntry of
        Just entry -> map MapOf (mapEntryModel entry)
        Nothing -> Right (Repeated (if packable value && packed then Packed else Expanded))
    | field.label == Just Descriptor.Required = Right Required
    | field.proto3Optional == Just true = Right Optional
    | isJust field.oneofIndex = Right InOneof
    | isMessage value || not proto3 = Right Optional
    | otherwise = Right Implicit
  isMessage = case _ of
    MessageValue _ -> true
    EnumValue _ -> false
    DoubleValue -> false
    FloatValue -> false
    Int64Value -> false
    UInt64Value -> false
    Int32Value -> false
    Fixed64Value -> false
    Fixed32Value -> false
    BoolValue -> false
    StringValue -> false
    BytesValue -> false
    UInt32Value -> false
    SFixed32Value -> false
    SFixed64Value -> false
    SInt32Value -> false
    SInt64Value -> false
  packed = case field.options >>= _.packed of
    Just explicit -> explicit
    Nothing -> proto3
  mapEntry = field.typeName >>= \typeName -> Map.lookup typeName symbols >>= _.mapEntry
  mapEntryModel entry = do
    key <- valueTypeOf symbols module_ imports entry.key
    value <- valueTypeOf symbols module_ imports entry.value
    let entryName = maybe "" _.name (field.typeName >>= \typeName -> Map.lookup typeName symbols)
    let protoName = maybe "" lastSegment field.typeName
    pure { reader: "read" <> entryName, protoName, key, value }

valueTypeOf :: Symbols -> String -> Array Import -> FieldDescriptorProto -> Either GeneratorError ValueType
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
  Just TypeGroup -> Left (GroupsUnsupported fieldName)
  Just (FieldDescriptorProto_TypeUnrecognized _) -> Left (UnknownFieldType fieldName)
  Nothing -> Left (UnknownFieldType fieldName)
  where
  fieldName = fromMaybe "" field.name
  reference = do
    typeName <- note (MissingTypeName fieldName) field.typeName
    symbol <- note (UnknownType fieldName typeName) (Map.lookup typeName symbols)
    pure
      { qualifier: if symbol.moduleName == module_ then "" else aliasOf imports symbol.moduleName
      , name: symbol.name
      , fullName: String.drop 1 typeName
      , recursive: symbol.recursive
      , zero: symbol.zero
      }

-- | A service's row type has its name, unless a message or enum of the file has that name too;
-- | then it's `GreeterService`.
serviceModel :: Symbols -> Comments -> String -> Array Import -> Array String -> String -> Int -> ServiceDescriptorProto -> Either GeneratorError ServiceModel
serviceModel symbols comments module_ imports taken scope serviceIndex serviceDescriptor = do
  methods <- sequence (Array.mapWithIndex methodModel serviceDescriptor.method)
  pure { fullName, comment: Map.lookup servicePath comments, typeName, valueName: Names.lowerFirst typeName, methods }
  where
  name = fromMaybe "" serviceDescriptor.name
  fullName = String.drop 1 (scope <> "." <> name)
  typeName = if Array.elem (Names.upperFirst name) taken then Names.upperFirst name <> "Service" else Names.upperFirst name
  servicePath = [ serviceField, serviceIndex ]
  serviceField = 6
  methodField = 2
  methodModel :: Int -> MethodDescriptorProto -> Either GeneratorError MethodModel
  methodModel methodIndex method = do
    let methodName = fromMaybe "" method.name
    request <- reference methodName method.inputType
    response <- reference methodName method.outputType
    pure
      { label: Names.recordLabel methodName
      , name: methodName
      , comment: Map.lookup (servicePath <> [ methodField, methodIndex ]) comments
      , procedure: "/" <> fullName <> "/" <> methodName
      , streaming: streamingOf (method.clientStreaming == Just true) (method.serverStreaming == Just true)
      , request
      , response
      }
  streamingOf clientStreams serverStreams
    | clientStreams && serverStreams = BothStreams
    | clientStreams = ClientStreams
    | serverStreams = ServerStreams
    | otherwise = NoStreams
  reference methodName messageTypeName = do
    found <- note (MissingTypeName methodName) messageTypeName
    symbol <- note (UnknownType methodName found) (Map.lookup found symbols)
    pure
      { qualifier: if symbol.moduleName == module_ then "" else aliasOf imports symbol.moduleName
      , name: symbol.name
      , fullName: String.drop 1 found
      , recursive: symbol.recursive
      , zero: symbol.zero
      }

enumModel :: Symbols -> Comments -> Found EnumDescriptorProto -> EnumModel
enumModel symbols comments found =
  { fullName: String.drop 1 found.fullName
  , comment: Map.lookup found.path comments
  , name: symbol.name
  , constructors: Array.zipWith (\constructor value -> { constructor, number: fromMaybe 0 value.number }) symbol.constructors found.descriptor.value
  , unrecognized: symbol.name <> "Unrecognized"
  }
  where
  symbol = fromMaybe noSymbol (Map.lookup found.fullName symbols)

noSymbol :: Declaration
noSymbol = { moduleName: "", name: "", recursive: false, mapEntry: Nothing, constructors: [], zero: "" }

-- | `Quote` of `.ticker.v1.Quote`.
lastSegment :: String -> String
lastSegment name = fromMaybe name (Array.last (String.split (Pattern ".") name))
