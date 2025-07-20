module Evergreen.V20.Shared.Model exposing (..)

import Evergreen.V20.Burpee
import Evergreen.V20.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V20.Burpee.Burpee
    , workoutHistory : List Evergreen.V20.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    , version : String
    , timeZone : Time.Zone
    }
