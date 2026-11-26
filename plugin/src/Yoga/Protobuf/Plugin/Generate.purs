-- | protoc-gen-purescript: from the request protoc sends to the modules it writes.
-- |
-- | Each file becomes a module of yoga-connect's types (see `Yoga.Protobuf.Plugin.Emit.Types`):
-- | messages, enums and services, from which yoga-connect works out the codecs, the server, the
-- | client and the `.proto` again. With the option `legacy` it becomes the module of records and
-- | generated codecs that protoc-gen-purescript wrote before.
-- |
-- | protoc passes options after `--purescript_out=`, separated by commas:
-- |
-- | - `legacy` generates records, codecs and a `Yoga.Connect.Service` value instead of types.
-- |   The rest are for it, except `module_prefix` and `services`.
-- | - `module_prefix=My.Modules` puts the modules under `My.Modules` instead of
-- |   `Yoga.Protobuf.Generated`
-- | - `fields_threshold=N` decodes messages with at least `N` plain fields in two steps. Without
-- |   it, every message is decoded in a loop, which is faster on Go for messages of any width:
-- |   with 50 fields 385 ns against 430, with 5 fields 32 against 38. On Bun two steps win
-- |   from 10 fields up, so a JavaScript-only project may want `fields_threshold=10`.
-- | - `services=none` leaves services out. Otherwise each becomes a `Service` type, or with
-- |   `legacy`, a row of its methods and a value with their routes and codecs.
module Yoga.Protobuf.Plugin.Generate
  ( run
  , generate
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Int as Int
import Data.Int64 as Int64
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Data.Traversable (traverse)

import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Plugin.Emit (moduleFor)
import Yoga.Protobuf.Plugin.Emit.Types (typesModuleFor, usesIn)
import Yoga.Protobuf.Plugin.Google.Protobuf.Compiler.Plugin (CodeGeneratorRequest, CodeGeneratorResponse, decodeCodeGeneratorRequest, defaultCodeGeneratorResponse, defaultCodeGeneratorResponse_File, encodeCodeGeneratorResponse)
import Yoga.Protobuf.Plugin.Names as Names
import Yoga.Protobuf.Plugin.Schema (describe, schemaOf)
import Yoga.Protobuf.Unsigned (UInt64(..))

-- | The encoded response to an encoded request.
run :: Bytes -> Bytes
run input = encodeCodeGeneratorResponse case decodeCodeGeneratorRequest input of
  Left error -> failed ("protoc-gen-purescript couldn't read the request: " <> show error)
  Right request -> generate request

-- | A module per file to generate, or the error that stopped the generator.
generate :: CodeGeneratorRequest -> CodeGeneratorResponse
generate request = case schemaOf prefix request.fileToGenerate request.protoFile of
  Left error -> failed (describe error)
  Right schema -> case traverse (moduleOf (usesIn schema)) (withoutServices schema) of
    Left error -> failed error
    Right files -> defaultCodeGeneratorResponse { supportedFeatures = Just proto3Optional, file = files }
  where
  parameters = parametersOf (fromMaybe "" request.parameter)
  parameter key = map _.value (Array.find (\entry -> entry.key == key) parameters)
  prefix = fromMaybe "Yoga.Protobuf.Generated" (parameter "module_prefix")
  fieldsThreshold = parameter "fields_threshold" >>= Int.fromString
  services = parameter "services" /= Just "none"
  legacy = isJust (parameter "legacy")
  withoutServices schema = if services then schema else schema <#> _ { services = [] }
  moduleOf uses model = contentOf uses model <#> \content -> defaultCodeGeneratorResponse_File
    { name = Just (Names.modulePath model.moduleName)
    , content = Just content
    }
  contentOf uses model
    | legacy = Right (moduleFor { fieldsThreshold, services } model)
    | otherwise = typesModuleFor uses model

-- | `FEATURE_PROTO3_OPTIONAL`: the generator knows `optional` in proto3 files.
proto3Optional :: UInt64
proto3Optional = UInt64 (Int64.fromInt 1)

failed :: String -> CodeGeneratorResponse
failed error = defaultCodeGeneratorResponse { error = Just error, supportedFeatures = Just proto3Optional }

parametersOf :: String -> Array { key :: String, value :: String }
parametersOf parameter = Array.mapMaybe pair (String.split (Pattern ",") parameter)
  where
  pair text = case String.indexOf (Pattern "=") text of
    Just index -> Just { key: String.trim (String.take index text), value: String.trim (String.drop (index + 1) text) }
    Nothing
      | String.trim text == "" -> Nothing
      | otherwise -> Just { key: String.trim text, value: "" }
