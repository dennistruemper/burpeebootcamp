module Types exposing (..)

import Bridge
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Burpee exposing (Burpee)
import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Main as ElmLand
import Url exposing (Url)


type alias FrontendModel =
    ElmLand.Model


type alias BackendModel =
    { users : Dict String UserData
    }


type alias FrontendMsg =
    ElmLand.Msg


type alias ToBackend =
    Bridge.ToBackend


type BackendMsg
    = OnConnect SessionId ClientId


type ToFrontend
    = LoggedIn UserData


type alias UserData =
    { currentConfig : Burpee
    , dailyTarget : Int
    , streak : Int
    }
