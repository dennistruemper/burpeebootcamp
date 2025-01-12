module Evergreen.V8.Pages.PickVariant exposing (..)

import Evergreen.V8.Burpee


type alias Model =
    { variants : List Evergreen.V8.Burpee.Burpee
    }


type Msg
    = PickedVariant Evergreen.V8.Burpee.Burpee
