{-# LANGUAGE OverloadedStrings #-}

module Main
  ( main
  ) where

import           Control.Monad.IO.Class         (liftIO)
import           Data.Morpheus                  (Interpreter (..))
import           Data.Morpheus.Server           (GQLState, gqlSocketApp, initGQLState)
import           Deprecated.API                 (gqlRoot)
import           Mythology.API                  (mythologyApi)
import qualified Network.Wai                    as Wai
import qualified Network.Wai.Handler.Warp       as Warp
import qualified Network.Wai.Handler.WebSockets as WaiWs
import           Network.WebSockets             (defaultConnectionOptions)
import           Web.Scotty                     (body, file, get, post, raw, scottyApp)

{-
const ws = new WebSocket('ws://localhost:3000/');
ws.send(JSON.stringify({"query":"query GetUser{user{name}}"}))
ws.send(JSON.stringify({"query":"mutation CreateUser{ createUser{name} }"}))
ws.send(JSON.stringify({"query":"subscription ShowNewUser{ newUser{name} }"}))
-}
main :: IO ()
main = do
  state <- initGQLState
  httpApp <- httpServer state
  Warp.runSettings settings $ WaiWs.websocketsOr defaultConnectionOptions (wsApp state) httpApp
  where
    settings = Warp.setPort 3000 Warp.defaultSettings
    wsApp = gqlSocketApp (interpreter gqlRoot)
    httpServer :: GQLState -> IO Wai.Application
    httpServer state =
      scottyApp $ do
        post "/" $ raw =<< (liftIO . interpreter gqlRoot state =<< body)
        get "/" $ file "examples/index.html"
        post "/mythology" $ raw =<< (liftIO . mythologyApi =<< body)
