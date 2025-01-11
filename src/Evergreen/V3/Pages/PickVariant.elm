module Evergreen.V3.Pages.PickVariant exposing (..)

import Evergreen.V3.Burpee


type alias Model =
    { variants : List Evergreen.V3.Burpee.Burpee
    }


type Msg
    = PickedVariant Evergreen.V3.Burpee.Burpee
