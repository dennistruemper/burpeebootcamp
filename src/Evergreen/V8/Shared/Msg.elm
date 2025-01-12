module Evergreen.V8.Shared.Msg exposing (..)

import Evergreen.V8.Burpee
import Evergreen.V8.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V8.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V8.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | NoOp
