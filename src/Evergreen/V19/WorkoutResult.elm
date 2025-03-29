module Evergreen.V19.WorkoutResult exposing (..)

import Evergreen.V19.Burpee
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
    , burpee : Evergreen.V19.Burpee.Burpee
    , timestamp : Time.Posix
    , sessionType : Maybe StoredSessionType
    }
