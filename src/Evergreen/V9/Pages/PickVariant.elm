module Evergreen.V9.Pages.PickVariant exposing (..)

import Evergreen.V9.Burpee


type alias Model =
    { variants : List Evergreen.V9.Burpee.Burpee
    , selectedVariant : Maybe Evergreen.V9.Burpee.Burpee
    , goalInput : String
    }


type Msg
    = PickedVariant Evergreen.V9.Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection
