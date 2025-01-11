module Evergreen.V3.Shared.Msg exposing (..)

import Evergreen.V3.Burpee
import Evergreen.V3.WorkoutResult
import Time


type Msg
    = BurpeePicked Evergreen.V3.Burpee.Burpee
    | StoreWorkoutResult Evergreen.V3.WorkoutResult.WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | NoOp
