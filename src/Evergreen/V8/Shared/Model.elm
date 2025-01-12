module Evergreen.V8.Shared.Model exposing (..)

import Evergreen.V8.Burpee
import Evergreen.V8.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V8.Burpee.Burpee
    , workoutHistory : List Evergreen.V8.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    }
