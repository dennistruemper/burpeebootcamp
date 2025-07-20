module Evergreen.V20.Types exposing (..)

import Dict
import Evergreen.V20.Bridge
import Evergreen.V20.Burpee
import Evergreen.V20.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V20.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V20.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V20.Main.Msg


type alias ToBackend =
    Evergreen.V20.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = NoOp
