-- @inline export snoc arity=2
-- @inline export snocFn never
-- @inline export freeze arity=1
-- @inline export thaw arity=1
-- | A growing array for the values of a repeated field while a decoder reads them.
-- |
-- | `snoc` adds in place, so a `Repeated` must be used linearly: once you `snoc` to one,
-- | or `freeze` it, don't touch the old one again. A decoder's accumulator is used like that.
-- |
-- | It's an array pushed to with `Data.Array.ST`, rather than a foreign type, because Iris
-- | knows `Data.Array.ST`: on Go a `Repeated` of records is a slice of structs, where a generic
-- | foreign function would hand each record over as an `any`.
module Yoga.Protobuf.Repeated
  ( Repeated
  , empty
  , snoc
  , snocFn
  , freeze
  , thaw
  ) where

import Prelude

import Control.Monad.ST as ST
import Data.Array as Array
import Data.Array.ST as STArray
import Data.Function.Uncurried (Fn2, mkFn2, runFn2)

-- | The values so far. Its constructor stays in this module: only `snoc` may push.
newtype Repeated a = Repeated (Array a)

-- | Nominal, so that `coerce` can't turn one into a `Repeated` of something else.
type role Repeated nominal

-- | No values. Every decoder starts from this one array, which `snoc` never pushes to.
empty :: forall a. Repeated a
empty = Repeated []

-- | Adds the value at the end, in place: the old `Repeated` mustn't be used again.
snoc :: forall a. Repeated a -> a -> Repeated a
snoc values value = runFn2 snocFn values value

-- | `snoc` as one uncurried function, which JavaScript calls without making closures.
snocFn :: forall a. Fn2 (Repeated a) a (Repeated a)
snocFn = mkFn2 \(Repeated values) value ->
  if Array.null values then Repeated [ value ]
  else Repeated (pushInPlace values value)
  where
  pushInPlace values value = ST.run do
    thawed <- STArray.unsafeThaw values
    _ <- STArray.push value thawed
    STArray.unsafeFreeze thawed

-- | The values as an array, without copying them.
freeze :: forall a. Repeated a -> Array a
freeze (Repeated values) = values

-- | Carries on with an array nothing else holds, without copying it.
thaw :: forall a. Array a -> Repeated a
thaw values = Repeated values
