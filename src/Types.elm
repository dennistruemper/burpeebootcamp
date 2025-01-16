module Types exposing (..)

import Bridge
import Burpee exposing (Burpee)
import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Main as ElmLand


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
    = NoOp


type alias UserData =
    { currentConfig : Burpee
    , dailyTarget : Int
    , streak : Int
    }
