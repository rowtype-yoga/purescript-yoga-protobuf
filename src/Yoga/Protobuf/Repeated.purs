-- | A growing array for the values of a repeated field while a decoder reads them.
-- |
-- | `snoc` adds in place, so a `Repeated` must be used linearly: once you `snoc` to one,
-- | or `freeze` it, don't touch the old one again. A decoder's accumulator is used like that.
module Yoga.Protobuf.Repeated
  ( Repeated
  , empty
  , snoc
  , freeze
  ) where

import Data.Function.Uncurried (Fn2, runFn2)

foreign import data Repeated :: Type -> Type

empty :: forall a. Repeated a
empty = emptyImpl

foreign import emptyImpl :: forall a. Repeated a

snoc :: forall a. Repeated a -> a -> Repeated a
snoc values value = runFn2 snocImpl values value

foreign import snocImpl :: forall a. Fn2 (Repeated a) a (Repeated a)

-- | The values as an array, without copying them.
freeze :: forall a. Repeated a -> Array a
freeze values = freezeImpl values

foreign import freezeImpl :: forall a. Repeated a -> Array a
