module Evergreen.V11.Pages.Counter exposing (..)

import Time


type alias Model =
    { currentReps : Int
    , overwriteRepGoal : Maybe Int
    , initialShowWelcomeModal : Bool
    }


type Msg
    = IncrementReps
    | ResetCounter
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime
    | ChangeToMenu
    | CloseWelcomeModal
