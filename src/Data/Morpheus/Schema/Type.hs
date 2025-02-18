{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeFamilies  #-}
{-# LANGUAGE TypeOperators #-}

module Data.Morpheus.Schema.Type
  ( Type(..)
  , DeprecationArgs(..)
  ) where

import           Data.Morpheus.Kind              (KIND, OBJECT)
import           Data.Morpheus.Schema.EnumValue  (EnumValue)
import qualified Data.Morpheus.Schema.Field      as F (Field (..))
import qualified Data.Morpheus.Schema.InputValue as I (InputValue (..))
import           Data.Morpheus.Schema.TypeKind   (TypeKind)
import           Data.Morpheus.Types.Resolver    ((::->))
import           Data.Text                       (Text)
import           GHC.Generics                    (Generic)

type instance KIND Type = OBJECT

data Type = Type
  { kind          :: TypeKind
  , name          :: Maybe Text
  , description   :: Maybe Text
  , fields        :: DeprecationArgs ::-> Maybe [F.Field Type]
  , ofType        :: Maybe Type
  , interfaces    :: Maybe [Type]
  , possibleTypes :: Maybe [Type]
  , enumValues    :: DeprecationArgs ::-> Maybe [EnumValue]
  , inputFields   :: Maybe [I.InputValue Type]
  } deriving (Generic)

newtype DeprecationArgs = DeprecationArgs
  { includeDeprecated :: Maybe Bool
  } deriving (Generic)
