module Evergreen.V6.Pages.PickVariant exposing (..)

import Evergreen.V6.Burpee


type alias Model =
    { variants : List Evergreen.V6.Burpee.Burpee
    }


type Msg
    = PickedVariant Evergreen.V6.Burpee.Burpee
