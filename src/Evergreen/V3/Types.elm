module Evergreen.V3.Types exposing (..)

import Dict
import Evergreen.V3.Bridge
import Evergreen.V3.Burpee
import Evergreen.V3.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V3.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V3.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V3.Main.Msg


type alias ToBackend =
    Evergreen.V3.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = LoggedIn UserData
