module Evergreen.V15.Main.Pages.Msg exposing (..)

import Evergreen.V15.Pages.Counter
import Evergreen.V15.Pages.Home_
import Evergreen.V15.Pages.Menu
import Evergreen.V15.Pages.NotFound_
import Evergreen.V15.Pages.PickVariant
import Evergreen.V15.Pages.Results


type Msg
    = Home_ Evergreen.V15.Pages.Home_.Msg
    | Counter Evergreen.V15.Pages.Counter.Msg
    | Menu Evergreen.V15.Pages.Menu.Msg
    | PickVariant Evergreen.V15.Pages.PickVariant.Msg
    | Results Evergreen.V15.Pages.Results.Msg
    | NotFound_ Evergreen.V15.Pages.NotFound_.Msg
