module Evergreen.V2.Types exposing (..)

import Dict
import Evergreen.V2.Bridge
import Evergreen.V2.Burpee
import Evergreen.V2.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V2.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V2.Burpee.BurpeeConfig
    , dailyTarget : Int
    , workoutHistory : List Evergreen.V2.Burpee.WorkoutStats
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V2.Main.Msg


type alias ToBackend =
    Evergreen.V2.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = LoggedIn UserData
