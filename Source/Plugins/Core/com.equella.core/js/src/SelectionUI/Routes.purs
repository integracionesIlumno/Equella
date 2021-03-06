module OEQ.SelectionUI.Routes where 

import Prelude

import Control.Alt ((<|>))
import Data.Either (either)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), drop, indexOf, take)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import OEQ.MainUI.Routes (pushRoute')
import OEQ.UI.Common (ClickableHref)
import React.SyntheticEvent (SyntheticEvent_, preventDefault, stopPropagation)
import Routing (match)
import Routing.Match (Match, end, int, lit, str)

data SessionParams = Session String (Maybe String)
data SelectionRoute = Route SessionParams SelectionPage
data SelectionPage = Search | ViewItem String Int 

paramsFromString :: String -> SessionParams
paramsFromString s = case indexOf (Pattern ":") s of 
    Just i -> Session (take i s) $ Just (drop (i+1) s)
    Nothing -> Session s Nothing

paramsToString :: SessionParams -> String 
paramsToString (Session s intid) = case intid of 
    Just i -> s <> ":" <> i 
    _ -> s

selectionRouteMatch :: Match SelectionRoute
selectionRouteMatch = Route <$> (lit "selection" *> (paramsFromString <$> str)) <*> selectionPageMatch

selectionPageMatch :: Match SelectionPage
selectionPageMatch = Search <$ (lit "search") <|>
     ViewItem <$> (lit "item" *> str) <*> int <|> 
     Search <$ end

matchSelection :: String -> Maybe SelectionRoute 
matchSelection = match selectionRouteMatch >>> (either (const Nothing) Just)

withPage :: Maybe SelectionRoute -> SelectionPage -> SelectionRoute 
withPage sr p = case sr of 
    Just (Route (Session sid iid) _) -> Route (Session sid iid) p
    _ -> Route (Session "FIXME" Nothing) p

selectionClicker :: SelectionRoute -> ClickableHref
selectionClicker r = 
    let href = selectionURI r
        onClick :: forall e. EffectFn1 (SyntheticEvent_ e) Unit
        onClick = mkEffectFn1 $ \e -> do 
          preventDefault e 
          stopPropagation e
          pushSelectionRoute r
    in { href, onClick }


selectionURI :: SelectionRoute -> String 
selectionURI (Route sess r) = "selection/" <> paramsToString sess <> "/" <> case r of 
    Search -> "search"
    ViewItem uuid ver -> "item/" <> uuid <> "/" <> show ver

pushSelectionRoute :: SelectionRoute -> Effect Unit
pushSelectionRoute = pushRoute' selectionURI