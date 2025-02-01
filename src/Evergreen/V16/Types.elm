module Evergreen.V16.Types exposing (..)

import Dict
import Evergreen.V16.Bridge
import Evergreen.V16.Burpee
import Evergreen.V16.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V16.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V16.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V16.Main.Msg


type alias ToBackend =
    Evergreen.V16.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = NoOp
