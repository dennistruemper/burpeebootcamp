module Evergreen.V11.Pages.PickVariant exposing (..)

import Evergreen.V11.Burpee


type alias Model =
    { variants : List Evergreen.V11.Burpee.Burpee
    , selectedVariant : Maybe Evergreen.V11.Burpee.Burpee
    , goalInput : String
    , first : Bool
    }


type Msg
    = PickedVariant Evergreen.V11.Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection
