module Data.Morpheus.Validation.Fragment
  ( validateFragments
  ) where

import qualified Data.Map                                      as M (toList)
import           Data.Morpheus.Error.Fragment                  (cannotSpreadWithinItself)
import           Data.Morpheus.Types.Internal.AST.RawSelection (Fragment (..), RawSelection (..), RawSelection' (..),
                                                                Reference (..))
import           Data.Morpheus.Types.Internal.Base             (EnhancedKey (..))
import           Data.Morpheus.Types.Internal.Data             (DataTypeLib)
import           Data.Morpheus.Types.Internal.Validation       (Validation)
import           Data.Morpheus.Types.Types                     (GQLQueryRoot (..))
import           Data.Morpheus.Validation.Utils.Utils          (existsObjectType)
import           Data.Text                                     (Text)

type Node = EnhancedKey

type NodeEdges = (Node, [Node])

type Graph = [NodeEdges]

scanForSpread :: DataTypeLib -> GQLQueryRoot -> (Text, RawSelection) -> [Node]
scanForSpread lib' root' (_, RawSelectionSet RawSelection' {rawSelectionRec = selection'}) =
  concatMap (scanForSpread lib' root') selection'
scanForSpread lib' root' (_, RawAlias {rawAliasSelection = selection'}) =
  concatMap (scanForSpread lib' root') [selection']
scanForSpread lib' root' (_, InlineFragment Fragment {fragmentSelection = selection'}) =
  concatMap (scanForSpread lib' root') selection'
scanForSpread _ _ (_, RawSelectionField {}) = []
scanForSpread _ _ (_, Spread Reference {referenceName = name', referencePosition = position'}) =
  [EnhancedKey name' position']

validateFragment :: DataTypeLib -> GQLQueryRoot -> (Text, Fragment) -> Validation NodeEdges
validateFragment lib' root (fName, Fragment { fragmentSelection = selection'
                                            , fragmentType = target'
                                            , fragmentPosition = position'
                                            }) =
  existsObjectType position' target' lib' >>
  pure (EnhancedKey fName position', concatMap (scanForSpread lib' root) selection')

validateFragments :: DataTypeLib -> GQLQueryRoot -> Validation ()
validateFragments lib root = mapM (validateFragment lib root) (M.toList $ fragments root) >>= detectLoopOnFragments

detectLoopOnFragments :: Graph -> Validation ()
detectLoopOnFragments lib = mapM_ checkFragment lib
  where
    checkFragment (fragmentID, _) = checkForCycle lib fragmentID [fragmentID]

checkForCycle :: Graph -> Node -> [Node] -> Validation Graph
checkForCycle lib parentNode history =
  case lookup parentNode lib of
    Just node -> concat <$> mapM checkNode node
    Nothing   -> pure []
  where
    checkNode x =
      if x `elem` history
        then cycleError x
        else recurse x
    recurse node = checkForCycle lib node $ history ++ [node]
    cycleError n = Left $ cannotSpreadWithinItself $ history ++ [n]
