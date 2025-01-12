module Evergreen.V8.Types exposing (..)

import Dict
import Evergreen.V8.Bridge
import Evergreen.V8.Burpee
import Evergreen.V8.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V8.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V8.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V8.Main.Msg


type alias ToBackend =
    Evergreen.V8.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = LoggedIn UserData
