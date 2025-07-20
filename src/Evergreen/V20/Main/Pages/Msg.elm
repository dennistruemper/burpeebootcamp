module Evergreen.V20.Main.Pages.Msg exposing (..)

import Evergreen.V20.Pages.Counter
import Evergreen.V20.Pages.Home_
import Evergreen.V20.Pages.Menu
import Evergreen.V20.Pages.NotFound_
import Evergreen.V20.Pages.PickVariant
import Evergreen.V20.Pages.Results


type Msg
    = Home_ Evergreen.V20.Pages.Home_.Msg
    | Counter Evergreen.V20.Pages.Counter.Msg
    | Menu Evergreen.V20.Pages.Menu.Msg
    | PickVariant Evergreen.V20.Pages.PickVariant.Msg
    | Results Evergreen.V20.Pages.Results.Msg
    | NotFound_ Evergreen.V20.Pages.NotFound_.Msg
