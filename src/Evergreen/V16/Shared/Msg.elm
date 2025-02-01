module Evergreen.V16.Shared.Msg exposing (..)

import Evergreen.V16.Burpee
import Evergreen.V16.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V16.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V16.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | GotTimeZone Time.Zone
    | NoOp
