module Evergreen.V19.Pages.PickVariant exposing (..)

import Evergreen.V19.Burpee


type alias Model =
    { variants : List Evergreen.V19.Burpee.Burpee
    , selectedVariant : Maybe Evergreen.V19.Burpee.Burpee
    , goalInput : String
    , first : Bool
    }


type Msg
    = PickedVariant Evergreen.V19.Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection
