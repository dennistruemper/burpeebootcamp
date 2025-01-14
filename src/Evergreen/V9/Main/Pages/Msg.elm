module Evergreen.V9.Main.Pages.Msg exposing (..)

import Evergreen.V9.Pages.Counter
import Evergreen.V9.Pages.Home_
import Evergreen.V9.Pages.Menu
import Evergreen.V9.Pages.NotFound_
import Evergreen.V9.Pages.PickVariant
import Evergreen.V9.Pages.Results


type Msg
    = Home_ Evergreen.V9.Pages.Home_.Msg
    | Counter Evergreen.V9.Pages.Counter.Msg
    | Menu Evergreen.V9.Pages.Menu.Msg
    | PickVariant Evergreen.V9.Pages.PickVariant.Msg
    | Results Evergreen.V9.Pages.Results.Msg
    | NotFound_ Evergreen.V9.Pages.NotFound_.Msg
