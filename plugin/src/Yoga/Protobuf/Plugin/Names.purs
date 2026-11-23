-- | How protocol buffer names become PureScript names.
module Yoga.Protobuf.Plugin.Names
  ( moduleName
  , modulePath
  , typeName
  , recordLabel
  , variable
  , pascalCase
  , enumPrefix
  , lowerFirst
  , upperFirst
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.CodeUnits as CodeUnits
import Data.String.Pattern (Pattern(..), Replacement(..))

-- | `google/protobuf/descriptor.proto` in `google.protobuf` under `Yoga.Protobuf.Generated` is
-- | `Yoga.Protobuf.Generated.Google.Protobuf.Descriptor`. A file named like the last part of its
-- | package, `bench.proto` in `bench`, doesn't repeat it: `Yoga.Protobuf.Generated.Bench`.
moduleName :: String -> String -> String -> String
moduleName prefix package file = String.joinWith "." (Array.filter (_ /= "") [ prefix ] <> segments)
  where
  packageSegments = map upperCamel (Array.filter (_ /= "") (String.split (Pattern ".") package))
  fileSegment = upperCamel (String.replaceAll (Pattern ".") (Replacement "_") (String.replaceAll (Pattern "-") (Replacement "_") (baseName file)))
  upperCamel name = String.joinWith "" (map upperFirst (String.split (Pattern "_") name))
  segments
    | Array.last packageSegments == Just fileSegment = packageSegments
    | otherwise = Array.snoc packageSegments fileSegment

-- | Where the module goes, relative to the output directory.
modulePath :: String -> String
modulePath name = String.replaceAll (Pattern ".") (Replacement "/") name <> ".purs"

-- | A message or enum nested in others joins their names: `Outer.Inner` is `Outer_Inner`.
typeName :: Array String -> String
typeName nesting = String.joinWith "_" (map upperFirst nesting)

-- | `file_to_generate` is `fileToGenerate`.
recordLabel :: String -> String
recordLabel fieldName = lowerFirst (camel (String.split (Pattern "_") fieldName))
  where
  camel parts = case Array.uncons (Array.filter (_ /= "") parts) of
    Nothing -> fieldName
    Just { head, tail } -> head <> String.joinWith "" (map upperFirst tail)

-- | The name of a local variable for a record label: the label, unless that's a keyword or a
-- | name the generated code uses itself.
variable :: String -> String
variable label = if Array.elem label taken then label <> "'" else label
  where
  taken =
    [ "ado", "as", "case", "class", "data", "derive", "do", "else", "false", "forall", "foreign"
    , "hiding", "if", "import", "in", "infix", "infixl", "infixr", "instance", "let", "module"
    , "newtype", "of", "then", "true", "type", "where"
    , "input", "start", "end", "position", "loop", "afterTag", "next", "payload", "text", "tag"
    , "value", "error", "decoded", "writer", "mark", "valueMark", "fields", "scan", "message"
    , "key", "number", "item", "record", "bytes", "at"
    , "when", "not", "zero", "pure", "unit", "show", "otherwise", "un", "failure", "mkFn3"
    , "runFn3", "runFn4", "decodeMessage", "encodeWith", "mapFromEntries", "packedInt32", "codec"
    ]

-- | `TYPE_UINT64` is `TypeUint64`, `optimize_mode` is `OptimizeMode`.
pascalCase :: String -> String
pascalCase name = String.joinWith "" (map capitalise (String.split (Pattern "_") name))
  where
  capitalise part = String.toUpper (CodeUnits.take 1 part) <> String.toLower (CodeUnits.drop 1 part)

-- | What the values of an enum start with if they follow the style guide: `FieldPresence` is
-- | `FIELD_PRESENCE_`.
enumPrefix :: String -> String
enumPrefix name = String.toUpper (CodeUnits.fromCharArray (go (CodeUnits.toCharArray name) Nothing [])) <> "_"
  where
  go characters previous done = case Array.uncons characters of
    Nothing -> done
    Just { head, tail }
      | isUpper head && fromMaybe false (map startsWord previous) -> go tail (Just head) (done <> [ '_', head ])
      | otherwise -> go tail (Just head) (Array.snoc done head)
  startsWord previous = isLower previous || isDigit previous
  isUpper character = character >= 'A' && character <= 'Z'
  isLower character = character >= 'a' && character <= 'z'
  isDigit character = character >= '0' && character <= '9'

baseName :: String -> String
baseName path = withoutExtension (fromMaybe path (Array.last (String.split (Pattern "/") path)))
  where
  withoutExtension name = fromMaybe name (String.stripSuffix (Pattern ".proto") name)

lowerFirst :: String -> String
lowerFirst name = String.toLower (CodeUnits.take 1 name) <> CodeUnits.drop 1 name

upperFirst :: String -> String
upperFirst name = String.toUpper (CodeUnits.take 1 name) <> CodeUnits.drop 1 name
