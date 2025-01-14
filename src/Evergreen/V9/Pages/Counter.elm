module Evergreen.V9.Pages.Counter exposing (..)

import Time


type alias Model =
    { currentReps : Int
    , overwriteRepGoal : Maybe Int
    }


type Msg
    = IncrementReps
    | ResetCounter
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime
    | ChangeToMenu
