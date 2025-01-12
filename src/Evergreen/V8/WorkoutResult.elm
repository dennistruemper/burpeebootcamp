module Evergreen.V8.WorkoutResult exposing (..)

import Evergreen.V8.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , repGoal : Maybe Int
    , burpee : Evergreen.V8.Burpee.Burpee
    , timestamp : Time.Posix
    }
