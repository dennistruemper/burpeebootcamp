module Evergreen.V3.Shared.Model exposing (..)

import Evergreen.V3.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , burpee : Evergreen.V3.Burpee.Burpee
    , timestamp : Time.Posix
    }


type alias Model =
    { currentBurpee : Maybe Evergreen.V3.Burpee.Burpee
    , currentRepGoal : Int
    , workoutHistory : List WorkoutResult
    , initializing : Bool
    }
