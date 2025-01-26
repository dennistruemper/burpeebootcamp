module Evergreen.V15.WorkoutResult exposing (..)

import Evergreen.V15.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , repGoal : Maybe Int
    , burpee : Evergreen.V15.Burpee.Burpee
    , timestamp : Time.Posix
    }
