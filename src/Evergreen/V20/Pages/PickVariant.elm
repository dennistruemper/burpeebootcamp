module Evergreen.V20.Pages.PickVariant exposing (..)

import Evergreen.V20.Burpee


type alias Model =
    { variants : List Evergreen.V20.Burpee.Burpee
    , selectedVariant : Maybe Evergreen.V20.Burpee.Burpee
    , goalInput : String
    , first : Bool
    }


type Msg
    = PickedVariant Evergreen.V20.Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection
