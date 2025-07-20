module Evergreen.V20.WorkoutResult exposing (..)

import Evergreen.V20.Burpee
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
    , burpee : Evergreen.V20.Burpee.Burpee
    , timestamp : Time.Posix
    , sessionType : Maybe StoredSessionType
    }
