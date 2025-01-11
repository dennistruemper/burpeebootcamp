module Evergreen.V6.Shared.Model exposing (..)

import Evergreen.V6.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , burpee : Evergreen.V6.Burpee.Burpee
    , timestamp : Time.Posix
    }


type alias Model =
    { currentBurpee : Maybe Evergreen.V6.Burpee.Burpee
    , currentRepGoal : Int
    , workoutHistory : List WorkoutResult
    , initializing : Bool
    }
