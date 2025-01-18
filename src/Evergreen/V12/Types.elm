module Evergreen.V12.Types exposing (..)

import Dict
import Evergreen.V12.Bridge
import Evergreen.V12.Burpee
import Evergreen.V12.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V12.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V12.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V12.Main.Msg


type alias ToBackend =
    Evergreen.V12.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = NoOp
