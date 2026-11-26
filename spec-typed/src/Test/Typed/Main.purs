module Test.Typed.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (defaultConfig, runSpec')
import Test.Typed.TypedSpec as TypedSpec

main :: Effect Unit
main = launchAff_ do
  runSpec' defaultConfig [ consoleReporter ] TypedSpec.spec
