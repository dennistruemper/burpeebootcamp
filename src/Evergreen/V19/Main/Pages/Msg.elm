module Evergreen.V19.Main.Pages.Msg exposing (..)

import Evergreen.V19.Pages.Counter
import Evergreen.V19.Pages.Home_
import Evergreen.V19.Pages.Menu
import Evergreen.V19.Pages.NotFound_
import Evergreen.V19.Pages.PickVariant
import Evergreen.V19.Pages.Results


type Msg
    = Home_ Evergreen.V19.Pages.Home_.Msg
    | Counter Evergreen.V19.Pages.Counter.Msg
    | Menu Evergreen.V19.Pages.Menu.Msg
    | PickVariant Evergreen.V19.Pages.PickVariant.Msg
    | Results Evergreen.V19.Pages.Results.Msg
    | NotFound_ Evergreen.V19.Pages.NotFound_.Msg
