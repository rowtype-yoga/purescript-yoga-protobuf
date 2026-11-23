-- @inline export snoc arity=2
-- | A growing array for the values of a repeated field while a decoder reads them.
-- |
-- | `snoc` adds in place, so a `Repeated` must be used linearly: once you `snoc` to one,
-- | or `freeze` it, don't touch the old one again. A decoder's accumulator is used like that.
-- |
-- | It's a Go slice that `snoc` appends to, and a JavaScript array it pushes to. Iris hands
-- | the Go functions its own types, as they never look into the values: a `Repeated` of
-- | records is a slice of structs.
module Yoga.Protobuf.Repeated
  ( Repeated
  , empty
  , snoc
  , snocFn
  , freeze
  , thaw
  ) where

import Data.Function.Uncurried (Fn2, runFn2)

-- | The values so far.
foreign import data Repeated :: Type -> Type

-- | Nominal, so that `coerce` can't turn one into a `Repeated` of something else.
type role Repeated nominal

-- | No values. On JavaScript every decoder starts from this one array, which `snoc` never
-- | pushes to.
foreign import empty :: forall a. Repeated a

-- | Adds the value at the end, in place: the old `Repeated` mustn't be used again.
snoc :: forall a. Repeated a -> a -> Repeated a
snoc values value = runFn2 snocFn values value

-- | `snoc` as one uncurried function, which JavaScript calls without making closures.
snocFn :: forall a. Fn2 (Repeated a) a (Repeated a)
snocFn = snocImpl

foreign import snocImpl :: forall a. Fn2 (Repeated a) a (Repeated a)

-- | The values as an array, without copying them.
foreign import freeze :: forall a. Repeated a -> Array a

-- | Carries on with an array nothing else holds, without copying it.
foreign import thaw :: forall a. Array a -> Repeated a
