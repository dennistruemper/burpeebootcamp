module Evergreen.V9.Types exposing (..)

import Dict
import Evergreen.V9.Bridge
import Evergreen.V9.Burpee
import Evergreen.V9.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V9.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V9.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V9.Main.Msg


type alias ToBackend =
    Evergreen.V9.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = LoggedIn UserData
