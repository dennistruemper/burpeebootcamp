module Evergreen.V16.Shared.Model exposing (..)

import Evergreen.V16.Burpee
import Evergreen.V16.WorkoutResult
import Time


type alias Model =
    { currentBurpee : Maybe Evergreen.V16.Burpee.Burpee
    , workoutHistory : List Evergreen.V16.WorkoutResult.WorkoutResult
    , initializing : Bool
    , currentTime : Time.Posix
    , version : String
    , timeZone : Time.Zone
    }
