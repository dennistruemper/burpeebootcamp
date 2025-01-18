module Evergreen.V12.WorkoutResult exposing (..)

import Evergreen.V12.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , repGoal : Maybe Int
    , burpee : Evergreen.V12.Burpee.Burpee
    , timestamp : Time.Posix
    }
