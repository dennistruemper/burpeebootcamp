module Evergreen.V11.Shared.Msg exposing (..)

import Evergreen.V11.Burpee
import Evergreen.V11.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V11.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V11.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | NoOp
