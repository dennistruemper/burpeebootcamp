module Evergreen.V19.Shared.Model exposing (..)

import Evergreen.V19.Burpee
import Evergreen.V19.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V19.Burpee.Burpee
    , workoutHistory : List Evergreen.V19.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    , version : String
    , timeZone : Time.Zone
    }
