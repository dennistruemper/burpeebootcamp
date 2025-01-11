module Evergreen.V3.WorkoutResult exposing (..)

import Evergreen.V3.Burpee
import Time


type alias WorkoutResult =
    { reps : Int
    , burpee : Evergreen.V3.Burpee.Burpee
    , timestamp : Time.Posix
    }
