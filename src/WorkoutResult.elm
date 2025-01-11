module WorkoutResult exposing (WorkoutResult)

import Burpee exposing (Burpee)
import Time


type alias WorkoutResult =
    { reps : Int
    , burpee : Burpee
    , timestamp : Time.Posix
    }
