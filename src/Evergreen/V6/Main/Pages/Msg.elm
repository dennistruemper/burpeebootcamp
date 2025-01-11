module Evergreen.V6.Main.Pages.Msg exposing (..)

import Evergreen.V6.Pages.Counter
import Evergreen.V6.Pages.Home_
import Evergreen.V6.Pages.Menu
import Evergreen.V6.Pages.NotFound_
import Evergreen.V6.Pages.PickVariant
import Evergreen.V6.Pages.Results


type Msg
    = Home_ Evergreen.V6.Pages.Home_.Msg
    | Counter Evergreen.V6.Pages.Counter.Msg
    | Menu Evergreen.V6.Pages.Menu.Msg
    | PickVariant Evergreen.V6.Pages.PickVariant.Msg
    | Results Evergreen.V6.Pages.Results.Msg
    | NotFound_ Evergreen.V6.Pages.NotFound_.Msg
