module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Bench.FixturesSpec as FixturesSpec
import Test.Bench.NestedSpec as NestedSpec
import Test.Bench.WideSpec as WideSpec
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (defaultConfig, runSpec')
import Test.Yoga.Protobuf.DecodeSpec as DecodeSpec
import Test.Yoga.Protobuf.WireSpec as WireSpec
import Test.Yoga.Protobuf.WriterSpec as WriterSpec

main :: Effect Unit
main = launchAff_ do
  runSpec' defaultConfig [ consoleReporter ] do
    WireSpec.spec
    WriterSpec.spec
    DecodeSpec.spec
    NestedSpec.spec
    WideSpec.spec
    FixturesSpec.spec
