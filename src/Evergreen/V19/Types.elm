module Evergreen.V19.Types exposing (..)

import Dict
import Evergreen.V19.Bridge
import Evergreen.V19.Burpee
import Evergreen.V19.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V19.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V19.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V19.Main.Msg


type alias ToBackend =
    Evergreen.V19.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = NoOp
