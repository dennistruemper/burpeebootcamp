module Evergreen.V19.Shared.Msg exposing (..)

import Evergreen.V19.Burpee
import Evergreen.V19.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V19.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V19.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | GotTimeZone Time.Zone
    | NoOp
