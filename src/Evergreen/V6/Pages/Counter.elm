module Evergreen.V6.Pages.Counter exposing (..)

import Time


type alias Model =
    { currentReps : Int
    }


type Msg
    = IncrementReps
    | ResetCounter
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime
    | ChangeToMenu
