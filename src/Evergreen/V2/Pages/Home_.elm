module Evergreen.V2.Pages.Home_ exposing (..)


type alias Model =
    { currentReps : Int
    }


type Msg
    = IncrementReps
    | ResetCounter
