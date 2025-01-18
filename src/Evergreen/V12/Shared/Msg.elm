module Evergreen.V12.Shared.Msg exposing (..)

import Evergreen.V12.Burpee
import Evergreen.V12.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V12.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V12.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | NoOp
