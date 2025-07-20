module Evergreen.V20.Shared.Msg exposing (..)

import Evergreen.V20.Burpee
import Evergreen.V20.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V20.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V20.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | GotTimeZone Time.Zone
    | NoOp
