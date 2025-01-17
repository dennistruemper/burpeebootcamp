module Evergreen.V11.WorkoutResult exposing (..)

import Evergreen.V11.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , repGoal : Maybe Int
    , burpee : Evergreen.V11.Burpee.Burpee
    , timestamp : Time.Posix
    }
