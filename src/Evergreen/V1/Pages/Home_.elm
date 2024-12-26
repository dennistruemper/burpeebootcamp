module Evergreen.V1.Pages.Home_ exposing (..)


type alias Model =
    { currentReps : Int
    }


type Msg
    = IncrementReps
    | ResetCounter
