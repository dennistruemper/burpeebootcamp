module Evergreen.V3.Pages.Home_ exposing (..)


type alias Model =
    { currentReps : Int
    }


type Msg
    = IncrementReps
    | ResetCounter
    | Redirect
