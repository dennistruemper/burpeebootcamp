module Shared.Model exposing (Model)

{-| -}

import Burpee exposing (Burpee)
import Time


{-| Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type alias Model =
    { currentBurpee : Maybe Burpee
    , currentRepGoal : Int
    , workoutHistory : List WorkoutResult
    , initializing : Bool
    }


type alias WorkoutResult =
    { reps : Int
    , burpee : Burpee
    , timestamp : Time.Posix
    }
