module Evergreen.V12.Shared.Model exposing (..)

import Evergreen.V12.Burpee
import Evergreen.V12.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V12.Burpee.Burpee
    , workoutHistory : List Evergreen.V12.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    , version : String
    }
