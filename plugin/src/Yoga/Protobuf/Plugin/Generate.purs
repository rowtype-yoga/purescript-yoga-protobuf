-- | protoc-gen-purescript: from the request protoc sends to the modules it writes.
-- |
-- | protoc passes options after `--purescript_out=`, separated by commas:
-- |
-- | - `module_prefix=My.Modules` puts the modules under `My.Modules` instead of
-- |   `Yoga.Protobuf.Generated`
-- | - `fields_threshold=N` decodes messages with at least `N` plain fields in two steps
module Yoga.Protobuf.Plugin.Generate
  ( run
  , generate
  , defaultFieldsThreshold
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Int as Int
import Data.Int64 as Int64
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Plugin.Emit (moduleFor)
import Yoga.Protobuf.Plugin.Google.Protobuf.Compiler.Plugin (CodeGeneratorRequest, CodeGeneratorResponse, decodeCodeGeneratorRequest, defaultCodeGeneratorResponse, defaultCodeGeneratorResponse_File, encodeCodeGeneratorResponse)
import Yoga.Protobuf.Plugin.Names as Names
import Yoga.Protobuf.Plugin.Schema (schemaOf)
import Yoga.Protobuf.Unsigned (UInt64(..))

-- | The encoded response to an encoded request.
run :: Bytes -> Bytes
run input = encodeCodeGeneratorResponse case decodeCodeGeneratorRequest input of
  Left error -> failed ("protoc-gen-purescript couldn't read the request: " <> show error)
  Right request -> generate request

generate :: CodeGeneratorRequest -> CodeGeneratorResponse
generate request = case schemaOf prefix request.fileToGenerate request.protoFile of
  Left error -> failed error
  Right schema -> defaultCodeGeneratorResponse
    { supportedFeatures = Just proto3Optional
    , file = map file schema
    }
  where
  parameters = parametersOf (fromMaybe "" request.parameter)
  parameter key = map _.value (Array.find (\entry -> entry.key == key) parameters)
  prefix = fromMaybe "Yoga.Protobuf.Generated" (parameter "module_prefix")
  fieldsThreshold = fromMaybe defaultFieldsThreshold (parameter "fields_threshold" >>= Int.fromString)
  file model = defaultCodeGeneratorResponse_File
    { name = Just (Names.modulePath model.moduleName)
    , content = Just (moduleFor { fieldsThreshold } model)
    }

-- | `FEATURE_PROTO3_OPTIONAL`: the generator knows `optional` in proto3 files.
proto3Optional :: UInt64
proto3Optional = UInt64 (Int64.fromInt 1)

-- | The fewest plain fields a message needs to be decoded in two steps.
defaultFieldsThreshold :: Int
defaultFieldsThreshold = 20

failed :: String -> CodeGeneratorResponse
failed error = defaultCodeGeneratorResponse { error = Just error, supportedFeatures = Just proto3Optional }

parametersOf :: String -> Array { key :: String, value :: String }
parametersOf parameter = Array.mapMaybe pair (String.split (Pattern ",") parameter)
  where
  pair text = case String.indexOf (Pattern "=") text of
    Just index -> Just { key: String.trim (String.take index text), value: String.trim (String.drop (index + 1) text) }
    Nothing -> Nothing
