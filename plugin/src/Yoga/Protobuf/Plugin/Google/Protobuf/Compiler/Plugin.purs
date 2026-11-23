-- | Bootstrap: the part of google/protobuf/compiler/plugin.proto the generator needs, written by
-- | hand, with the names and types the generator gives them. The generator replaces this module
-- | with its own output for plugin.proto.
module Yoga.Protobuf.Plugin.Google.Protobuf.Compiler.Plugin where

import Prelude

import Data.Array as Array
import Data.Either (Either)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Decode (Reader, decodeMessage)
import Yoga.Protobuf.Error (DecodeError)
import Yoga.Protobuf.Plugin.Google.Protobuf.Descriptor as Descriptor
import Yoga.Protobuf.Unsigned (UInt64(..))
import Yoga.Protobuf.Writer (Writer, encodeWith)
import Yoga.Protobuf.Writer as Writer

type CodeGeneratorRequest =
  { fileToGenerate :: Array String
  , parameter :: Maybe String
  , protoFile :: Array Descriptor.FileDescriptorProto
  }

type CodeGeneratorResponse =
  { error :: Maybe String
  , supportedFeatures :: Maybe UInt64
  , file :: Array CodeGeneratorResponse_File
  }

type CodeGeneratorResponse_File =
  { name :: Maybe String
  , content :: Maybe String
  }

defaultCodeGeneratorResponse :: CodeGeneratorResponse
defaultCodeGeneratorResponse = { error: Nothing, supportedFeatures: Nothing, file: [] }

defaultCodeGeneratorResponse_File :: CodeGeneratorResponse_File
defaultCodeGeneratorResponse_File = { name: Nothing, content: Nothing }

decodeCodeGeneratorRequest :: Bytes -> Either DecodeError CodeGeneratorRequest
decodeCodeGeneratorRequest input = decodeMessage readCodeGeneratorRequest input

encodeCodeGeneratorResponse :: CodeGeneratorResponse -> Bytes
encodeCodeGeneratorResponse response = encodeWith writeCodeGeneratorResponse response

readCodeGeneratorRequest :: Reader CodeGeneratorRequest
readCodeGeneratorRequest = Descriptor.messageOf
  { fileToGenerate: [], parameter: Nothing, protoFile: [] }
  case _ of
    10 -> Descriptor.string \value record -> record { fileToGenerate = Array.snoc record.fileToGenerate value }
    18 -> Descriptor.string \value record -> record { parameter = Just value }
    122 -> Descriptor.message Descriptor.readFileDescriptorProto \value record -> record { protoFile = Array.snoc record.protoFile value }
    _ -> Descriptor.skip

writeCodeGeneratorResponse :: Writer -> CodeGeneratorResponse -> Effect Unit
writeCodeGeneratorResponse writer response = do
  Writer.eachDescending response.file \file -> do
    mark <- Writer.written writer
    writeCodeGeneratorResponse_File writer file
    Writer.lengthSince writer mark
    Writer.tag writer 122
  case response.supportedFeatures of
    Nothing -> pure unit
    Just (UInt64 features) -> do
      Writer.int64 writer features
      Writer.tag writer 16
  case response.error of
    Nothing -> pure unit
    Just error -> do
      Writer.string writer error
      Writer.tag writer 10

writeCodeGeneratorResponse_File :: Writer -> CodeGeneratorResponse_File -> Effect Unit
writeCodeGeneratorResponse_File writer file = do
  case file.content of
    Nothing -> pure unit
    Just content -> do
      Writer.string writer content
      Writer.tag writer 122
  case file.name of
    Nothing -> pure unit
    Just name -> do
      Writer.string writer name
      Writer.tag writer 10
