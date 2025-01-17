module Evergreen.V11.Shared.Model exposing (..)

import Evergreen.V11.Burpee
import Evergreen.V11.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V11.Burpee.Burpee
    , workoutHistory : List Evergreen.V11.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    , version : String
    }
