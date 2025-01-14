module Evergreen.V9.WorkoutResult exposing (..)

import Evergreen.V9.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , repGoal : Maybe Int
    , burpee : Evergreen.V9.Burpee.Burpee
    , timestamp : Time.Posix
    }
