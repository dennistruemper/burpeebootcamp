module Evergreen.V16.Pages.PickVariant exposing (..)

import Evergreen.V16.Burpee


type alias Model =
    { variants : List Evergreen.V16.Burpee.Burpee
    , selectedVariant : Maybe Evergreen.V16.Burpee.Burpee
    , goalInput : String
    , first : Bool
    }


type Msg
    = PickedVariant Evergreen.V16.Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection
