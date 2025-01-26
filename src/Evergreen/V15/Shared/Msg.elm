module Evergreen.V15.Shared.Msg exposing (..)

import Evergreen.V15.Burpee
import Evergreen.V15.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V15.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V15.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | NoOp
