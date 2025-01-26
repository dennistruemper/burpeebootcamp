module Evergreen.V15.Shared.Model exposing (..)

import Evergreen.V15.Burpee
import Evergreen.V15.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V15.Burpee.Burpee
    , workoutHistory : List Evergreen.V15.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    , version : String
    }
