module Evergreen.V1.Types exposing (..)

import Dict
import Evergreen.V1.Bridge
import Evergreen.V1.Burpee
import Evergreen.V1.Main
import Lamdera


type alias FrontendModel =
    Evergreen.V1.Main.Model


type alias UserData =
    { currentConfig : Evergreen.V1.Burpee.BurpeeConfig
    , dailyTarget : Int
    , workoutHistory : List Evergreen.V1.Burpee.WorkoutStats
    , streak : Int
    }


type alias BackendModel =
    { users : Dict.Dict String UserData
    }


type alias FrontendMsg =
    Evergreen.V1.Main.Msg


type alias ToBackend =
    Evergreen.V1.Bridge.ToBackend


type BackendMsg
    = OnConnect Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = LoggedIn UserData
