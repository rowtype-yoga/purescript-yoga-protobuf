-- | The imports of a generated module: those of its code's names that it uses, so that it
-- | compiles without warnings.
module Yoga.Protobuf.Plugin.Imports
  ( importsFor
  , typeImportsFor
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.Set (Set)
import Data.Set as Set
import Data.String as String
import Data.String.CodeUnits as CodeUnits
import Data.String.Pattern (Pattern(..))

import Yoga.Protobuf.Plugin.Schema (Import)

-- | Three blocks: `import Prelude`, the libraries the code uses, then the other generated
-- | modules it uses, each sorted by module.
importsFor :: Array Import -> Array String -> Array String
importsFor generated body =
  [ "import Prelude", "" ]
    <> sorted (librariesFor tokens)
    <> (if Array.null localImports then [] else [ "" ] <> localImports)
  where
  tokens = tokensOf (String.joinWith "\n" body)
  localImports = sorted (map (\entry -> Qualified entry.moduleName entry.alias) generated)
  sorted candidates = map _.text (Array.sortWith _.moduleName (Array.mapMaybe (used tokens) candidates))

data Candidate
  = Qualified String String
  -- | A module's names, each imported if the code has any of its tokens.
  | Names String (Array { tokens :: Array String, name :: String })

used :: Set String -> Candidate -> Maybe { moduleName :: String, text :: String }
used tokens = case _ of
  Qualified moduleName alias
    | Array.any (\token -> String.indexOf (Pattern (alias <> ".")) token == Just 0) (Array.fromFoldable tokens) ->
        Just { moduleName, text: "import " <> moduleName <> " as " <> alias }
    | otherwise -> Nothing
  Names moduleName names -> case Array.filter (\entry -> Array.any (\token -> Set.member token tokens) entry.tokens) names of
    [] -> Nothing
    found -> Just { moduleName, text: "import " <> moduleName <> " (" <> String.joinWith ", " (map _.name found) <> ")" }

-- | The libraries generated code with these tokens may use.
librariesFor :: Set String -> Array Candidate
librariesFor tokens =
  [ Qualified "Data.Array" "Array"
  , Names "Data.Either" [ { tokens: [ "Either", "Left", "Right" ], name: "Either(..)" } ]
  , Names "Data.Function.Uncurried" [ named "mkFn3", named "runFn3", named "runFn4" ]
  , Names "Data.Int64" [ named "Int64" ]
  , Names "Data.Map" [ named "Map" ]
  , Qualified "Data.Map" "Map"
  , Names "Data.Maybe" [ { tokens: [ "Maybe", "Just", "Nothing" ], name: "Maybe(..)" } ]
  , Names "Data.Newtype" [ { tokens: [ "Newtype" ], name: "class Newtype" }, named "un" ]
  , Names "Data.Variant" [ named "Variant" ]
  , Qualified "Data.Variant" "Variant"
  , Names "Effect" [ named "Effect" ]
  , Names "Type.Proxy" [ { tokens: [ "Proxy" ], name: "Proxy(..)" } ]
  , Qualified "Yoga.Connect.Service" "Connect"
  , Names "Yoga.Protobuf.Bytes" [ named "Bytes" ]
  , Qualified "Yoga.Protobuf.Bytes" "Bytes"
  , Names "Yoga.Protobuf.Codec" [ named "Codec", named "codec" ]
  , Names "Yoga.Protobuf.Decode" [ named "Entry", named "Reader", named "decodeMessage", named "mapFromEntries", named "packedInt32" ]
  , Qualified "Yoga.Protobuf.Decode" "Decode"
  , Names "Yoga.Protobuf.Error" [ decodeError, named "failure" ]
  , Qualified "Yoga.Protobuf.Fields" "Fields"
  , Qualified "Yoga.Protobuf.Repeated" "Repeated"
  , Names "Yoga.Protobuf.Unsigned" [ { tokens: [ "UInt32" ], name: "UInt32(..)" }, { tokens: [ "UInt64" ], name: "UInt64(..)" } ]
  , Qualified "Yoga.Protobuf.Wire" "Wire"
  , Names "Yoga.Protobuf.Writer" [ named "Writer", named "encodeWith" ]
  , Qualified "Yoga.Protobuf.Writer" "Writer"
  ]
  where
  named name = { tokens: [ name ], name }
  -- `DecodeError` is in every decoder's type, its constructors only where a decoder makes one.
  decodeError
    | Array.any (\constructor -> Set.member constructor tokens) [ "InvalidUtf8", "MalformedVarint", "Truncated" ] = { tokens: [ "DecodeError" ], name: "DecodeError(..)" }
    | otherwise = named "DecodeError"

-- | The names in the code: runs of letters, digits, `_`, `'` and `.`.
tokensOf :: String -> Set String
tokensOf text = Set.fromFoldable (String.split (Pattern " ") (CodeUnits.fromCharArray (map separate (CodeUnits.toCharArray text))))
  where
  separate character
    | (character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') || (character >= '0' && character <= '9') = character
    | character == '_' || character == '\'' || character == '.' = character
    | otherwise = ' '

-- | The imports of a module of types: `Prelude` if it `derives` instances, the libraries, then
-- | the other generated modules. A library type with the name of one of the module's `ownNames`
-- | is imported qualified, and only used so.
typeImportsFor :: { derives :: Boolean, ownNames :: Array String } -> Array Import -> Array String -> Array String
typeImportsFor { derives, ownNames } generated body = prelude <> libraries <> (if Array.null localImports then [] else [ "" ] <> localImports)
  where
  prelude = if derives then [ "import Prelude", "" ] else []
  code = String.joinWith "\n" (Array.filter (not <<< String.contains (Pattern "-- |")) body)
  tokens = (if String.contains (Pattern " := ") code then Set.insert ":=" else identity) (tokensOf code)
  libraries = Array.sort (typeLibraries >>= importsOfLibrary)
  importsOfLibrary library = Array.catMaybes [ unqualified library, qualified library ]
  unqualified library = case Array.filter (\entry -> Set.member entry.token tokens && not (Array.elem entry.token ownNames)) library.names of
    [] -> Nothing
    found -> Just ("import " <> library.moduleName <> " (" <> String.joinWith ", " (map _.name found) <> ")")
  qualified library = case library.alias of
    Just alias | Array.any (\entry -> Set.member (alias <> "." <> entry.token) tokens) library.names -> Just ("import " <> library.moduleName <> " as " <> alias)
    _ -> Nothing
  localImports = sorted (map (\entry -> Qualified entry.moduleName entry.alias) generated)
  sorted candidates = map _.text (Array.sortWith _.moduleName (Array.mapMaybe (used tokens) candidates))

-- | The libraries a module of types may use, and the alias of those whose types a generated
-- | type's name can clash with.
typeLibraries :: Array { moduleName :: String, alias :: Maybe String, names :: Array { token :: String, name :: String } }
typeLibraries =
  [ { moduleName: "Data.Generic.Rep", alias: Nothing, names: [ { token: "Generic", name: "class Generic" } ] }
  , { moduleName: "Data.Int64", alias: Just "Int64", names: [ named "Int64" ] }
  , { moduleName: "Data.Maybe", alias: Just "Maybe", names: [ named "Maybe" ] }
  , { moduleName: "Data.Show.Generic", alias: Nothing, names: [ named "genericShow" ] }
  , { moduleName: "Yoga.Connect.Message", alias: Just "Connect", names: [ { token: ":=", name: "type (:=)" }, named "Message", named "Named", named "OneOf" ] }
  , { moduleName: "Yoga.Connect.Schema", alias: Just "Connect", names: [ named "BidiStream", named "ClientStream", named "ServerStream", named "Service", named "Unary" ] }
  , { moduleName: "Yoga.Protobuf.Bytes", alias: Just "Bytes", names: [ named "Bytes" ] }
  , { moduleName: "Yoga.Protobuf.Unsigned", alias: Just "Unsigned", names: [ named "UInt32", named "UInt64" ] }
  ]
  where
  named name = { token: name, name }
