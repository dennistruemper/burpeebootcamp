module Evergreen.V15.Pages.PickVariant exposing (..)

import Evergreen.V15.Burpee


type alias Model =
    { variants : List Evergreen.V15.Burpee.Burpee
    , selectedVariant : Maybe Evergreen.V15.Burpee.Burpee
    , goalInput : String
    , first : Bool
    }


type Msg
    = PickedVariant Evergreen.V15.Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection
