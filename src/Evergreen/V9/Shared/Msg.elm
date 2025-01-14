module Evergreen.V9.Shared.Msg exposing (..)

import Evergreen.V9.Burpee
import Evergreen.V9.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V9.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V9.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | NoOp
