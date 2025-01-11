module Evergreen.V6.Types exposing (..)

import Dict
import Evergreen.V6.Bridge
import Evergreen.V6.Burpee
import Evergreen.V6.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V6.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V6.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V6.Main.Msg


type alias ToBackend =
    Evergreen.V6.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = LoggedIn UserData
