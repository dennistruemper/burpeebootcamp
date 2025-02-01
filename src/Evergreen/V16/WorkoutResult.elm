module Evergreen.V16.WorkoutResult exposing (..)

import Evergreen.V16.Burpee
import Time


type StoredSessionType
    = StoredAMRAP
        { duration : Int
        }
    | StoredEMOM
    | StoredWorkout
    | StoredFree


type alias WorkoutResult =
    { reps : Int
    , repGoal : Maybe Int
    , burpee : Evergreen.V16.Burpee.Burpee
    , timestamp : Time.Posix
    , sessionType : Maybe StoredSessionType
    }
