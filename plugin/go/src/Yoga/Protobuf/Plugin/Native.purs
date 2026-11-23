-- | protoc-gen-purescript as a native binary: reads protoc's request from standard input and
-- | writes the response to standard output, through purescript-go.
module Yoga.Protobuf.Plugin.Native
  ( main
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Newtype (un)
import Effect (Effect)
import Go.Error (ErrorMessage(..), message)
import Go.OS (ExitCode(..), exit)
import Go.OS.Stdio as Stdio

import Yoga.Protobuf.Plugin.Generate (run)
import Yoga.Protobuf.Plugin.GoBytes (fromYoga, toYoga)

-- | Answers the one request protoc sends, or says on standard error why it can't.
main :: Effect Unit
main = do
  input <- Stdio.readAllBytes
  case input of
    Left error -> failWith ("protoc-gen-purescript couldn't read standard input: " <> un ErrorMessage (message error))
    Right request -> do
      written <- Stdio.writeStdoutBytes (fromYoga (run (toYoga request)))
      case written of
        Left error -> failWith ("protoc-gen-purescript couldn't write standard output: " <> un ErrorMessage (message error))
        Right _ -> pure unit
  where
  failWith text = do
    _ <- Stdio.writeStderr (text <> "\n")
    exit (ExitCode 1)
