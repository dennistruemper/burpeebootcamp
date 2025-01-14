module Evergreen.V9.Shared.Model exposing (..)

import Evergreen.V9.Burpee
import Evergreen.V9.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V9.Burpee.Burpee
    , workoutHistory : List Evergreen.V9.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    }
