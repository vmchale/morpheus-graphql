{-# LANGUAGE OverloadedStrings #-}

module Main
  ( main
  ) where

import qualified Feature.Holistic.API  as Holistic (api)
import qualified Feature.InputType.API as InputType (api)
import qualified Feature.UnionType.API as UnionType (api)
import           Test.Tasty            (defaultMain, testGroup)
import           TestFeature           (testFeature)

main :: IO ()
main = do
  ioTests <- testFeature Holistic.api "Feature/Holistic"
  unionTest <- testFeature UnionType.api "Feature/UnionType"
  inputTest <- testFeature InputType.api "Feature/InputType"
  defaultMain (testGroup "Morpheus Graphql Tests" [ioTests, unionTest, inputTest])
