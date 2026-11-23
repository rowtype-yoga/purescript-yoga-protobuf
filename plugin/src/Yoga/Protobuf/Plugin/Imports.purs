-- | The imports of a generated module: those of its code's names that it uses, so that it
-- | compiles without warnings.
module Yoga.Protobuf.Plugin.Imports
  ( importsFor
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.Set (Set)
import Data.Set as Set
import Data.String as String
import Data.String.CodeUnits as CodeUnits
import Data.String.Pattern (Pattern(..))
import Data.Tuple.Nested (type (/\), (/\))
import Yoga.Protobuf.Plugin.Schema (Import)

-- | `import Prelude`, a blank line and the imports the code uses, sorted by module.
importsFor :: Array Import -> Array String -> Array String
importsFor generated body = [ "import Prelude", "" ] <> map render (Array.sortWith _.moduleName (Array.mapMaybe used candidates))
  where
  tokens = tokensOf (String.joinWith "\n" body)
  has name = Set.member name tokens
  qualifies alias = Array.any (\token -> String.indexOf (Pattern (alias <> ".")) token == Just 0) (Array.fromFoldable tokens)
  used = case _ of
    Qualified moduleName alias
      | qualifies alias -> Just { moduleName, text: "import " <> moduleName <> " as " <> alias }
      | otherwise -> Nothing
    Names moduleName names -> case Array.filter (\(token /\ _) -> Array.any has token) names of
      [] -> Nothing
      found -> Just { moduleName, text: "import " <> moduleName <> " (" <> String.joinWith ", " (map (\(_ /\ name) -> name) found) <> ")" }
  render found = found.text
  candidates =
    [ Qualified "Data.Array" "Array"
    , Names "Data.Either" [ [ "Either", "Left", "Right" ] /\ "Either(..)" ]
    , Names "Data.Function.Uncurried" [ [ "mkFn3" ] /\ "mkFn3", [ "runFn3" ] /\ "runFn3", [ "runFn4" ] /\ "runFn4" ]
    , Names "Data.Int64" [ [ "Int64" ] /\ "Int64" ]
    , Names "Data.Map" [ [ "Map" ] /\ "Map" ]
    , Qualified "Data.Map" "Map"
    , Names "Data.Maybe" [ [ "Maybe", "Just", "Nothing" ] /\ "Maybe(..)" ]
    , Names "Data.Newtype" [ [ "Newtype" ] /\ "class Newtype", [ "un" ] /\ "un" ]
    , Names "Data.Variant" [ [ "Variant" ] /\ "Variant" ]
    , Qualified "Data.Variant" "Variant"
    , Names "Effect" [ [ "Effect" ] /\ "Effect" ]
    , Names "Type.Proxy" [ [ "Proxy" ] /\ "Proxy(..)" ]
    , Names "Yoga.Protobuf.Bytes" [ [ "Bytes" ] /\ "Bytes" ]
    , Qualified "Yoga.Protobuf.Bytes" "Bytes"
    , Names "Yoga.Protobuf.Codec" [ [ "Codec" ] /\ "Codec", [ "codec" ] /\ "codec" ]
    , Names "Yoga.Protobuf.Decode"
        [ [ "Entry" ] /\ "Entry"
        , [ "Reader" ] /\ "Reader"
        , [ "decodeMessage" ] /\ "decodeMessage"
        , [ "mapFromEntries" ] /\ "mapFromEntries"
        , [ "packedInt32" ] /\ "packedInt32"
        ]
    , Qualified "Yoga.Protobuf.Decode" "Decode"
    , Names "Yoga.Protobuf.Error" [ errorType, [ "failure" ] /\ "failure" ]
    , Qualified "Yoga.Protobuf.Fields" "Fields"
    , Qualified "Yoga.Protobuf.Repeated" "Repeated"
    , Names "Yoga.Protobuf.Unsigned" [ [ "UInt32" ] /\ "UInt32(..)", [ "UInt64" ] /\ "UInt64(..)" ]
    , Qualified "Yoga.Protobuf.Wire" "Wire"
    , Names "Yoga.Protobuf.Writer" [ [ "Writer" ] /\ "Writer", [ "encodeWith" ] /\ "encodeWith" ]
    , Qualified "Yoga.Protobuf.Writer" "Writer"
    ]
      <> map (\entry -> Qualified entry.moduleName entry.alias) generated
  -- `DecodeError` is in every decoder's type; its constructors only where a decoder makes one.
  errorType
    | Array.any has [ "InvalidUtf8", "MalformedVarint", "Truncated" ] = [ "DecodeError" ] /\ "DecodeError(..)"
    | otherwise = [ "DecodeError" ] /\ "DecodeError"

data Candidate
  = Qualified String String
  | Names String (Array (Array String /\ String))

-- | The names in the code: runs of letters, digits, `_`, `'` and `.`.
tokensOf :: String -> Set String
tokensOf text = Set.fromFoldable (String.split (Pattern " ") (CodeUnits.fromCharArray (map separate (CodeUnits.toCharArray text))))
  where
  separate character
    | (character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') || (character >= '0' && character <= '9') = character
    | character == '_' || character == '\'' || character == '.' = character
    | otherwise = ' '
