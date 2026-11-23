module Yoga.Protobuf.Error
  ( DecodeError(..)
  , Position
  , failure
  ) where

import Prelude

-- | The byte offset in the input where decoding went wrong.
type Position = Int

data DecodeError
  = Truncated Position
  | MalformedVarint Position
  | InvalidWireType Position
  | InvalidUtf8 Position

derive instance Eq DecodeError

instance Show DecodeError where
  show = case _ of
    Truncated position -> "(Truncated " <> show position <> ")"
    MalformedVarint position -> "(MalformedVarint " <> show position <> ")"
    InvalidWireType position -> "(InvalidWireType " <> show position <> ")"
    InvalidUtf8 position -> "(InvalidUtf8 " <> show position <> ")"

-- | The error a negative position from `Yoga.Protobuf.Wire` stands for, at `position`.
failure :: Int -> Position -> DecodeError
failure code position
  | code == -2 = MalformedVarint position
  | code == -3 = InvalidWireType position
  | code == -4 = InvalidUtf8 position
  | otherwise = Truncated position
