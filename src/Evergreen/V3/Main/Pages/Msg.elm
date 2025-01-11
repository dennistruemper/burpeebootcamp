module Evergreen.V3.Main.Pages.Msg exposing (..)

import Evergreen.V3.Pages.Counter
import Evergreen.V3.Pages.Home_
import Evergreen.V3.Pages.NotFound_
import Evergreen.V3.Pages.PickVariant


type Msg
    = Home_ Evergreen.V3.Pages.Home_.Msg
    | Counter Evergreen.V3.Pages.Counter.Msg
    | PickVariant Evergreen.V3.Pages.PickVariant.Msg
    | NotFound_ Evergreen.V3.Pages.NotFound_.Msg
