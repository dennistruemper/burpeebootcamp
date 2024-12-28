module Evergreen.V2.Pages.Counter exposing (..)


type alias Model =
    { currentReps : Int
    }


type Msg
    = IncrementReps
    | ResetCounter
