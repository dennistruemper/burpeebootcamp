module Evergreen.V6.WorkoutResult exposing (..)

import Evergreen.V6.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , burpee : Evergreen.V6.Burpee.Burpee
    , timestamp : Time.Posix
    }
