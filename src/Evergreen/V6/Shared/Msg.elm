module Evergreen.V6.Shared.Msg exposing (..)

import Evergreen.V6.Burpee
import Evergreen.V6.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V6.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V6.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | GotTime Time.Posix
    | GotTimeForFakedata Time.Posix
    | NoOp
