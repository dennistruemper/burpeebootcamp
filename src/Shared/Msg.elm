module Shared.Msg exposing (Msg(..))

{-| -}

import Burpee exposing (Burpee)
import Ports
import Time
import WorkoutResult exposing (WorkoutResult)


{-| Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type Msg
    = BurpeePicked Burpee
    | StoreWorkoutResult WorkoutResult
    | GotPortMessage String
    | GotTimeForRepGoalCalculation Time.Posix
    | NoOp
