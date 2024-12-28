module Evergreen.V2.Main.Pages.Msg exposing (..)

import Evergreen.V2.Pages.Counter
import Evergreen.V2.Pages.Home_
import Evergreen.V2.Pages.NotFound_


type Msg
    = Home_ Evergreen.V2.Pages.Home_.Msg
    | Counter Evergreen.V2.Pages.Counter.Msg
    | NotFound_ Evergreen.V2.Pages.NotFound_.Msg
