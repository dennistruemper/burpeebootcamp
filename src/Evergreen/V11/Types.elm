module Evergreen.V11.Types exposing (..)

import Dict
import Evergreen.V11.Bridge
import Evergreen.V11.Burpee
import Evergreen.V11.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V11.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V11.Burpee.Burpee
    , dailyTarget : Int
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V11.Main.Msg


type alias ToBackend =
    Evergreen.V11.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = NoOp
