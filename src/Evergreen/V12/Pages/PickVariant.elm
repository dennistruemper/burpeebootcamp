module Evergreen.V12.Pages.PickVariant exposing (..)

import Evergreen.V12.Burpee


type alias Model =
    { variants : List Evergreen.V12.Burpee.Burpee
    , selectedVariant : Maybe Evergreen.V12.Burpee.Burpee
    , goalInput : String
    , first : Bool
    }


type Msg
    = PickedVariant Evergreen.V12.Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection
