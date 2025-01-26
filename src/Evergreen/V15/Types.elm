module Evergreen.V15.Types exposing (..)

import Dict
import Evergreen.V15.Bridge
import Evergreen.V15.Burpee
import Evergreen.V15.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V15.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V15.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V15.Main.Msg


type alias ToBackend =
    Evergreen.V15.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = NoOp
