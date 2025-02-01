module Evergreen.V16.Main.Pages.Msg exposing (..)

import Evergreen.V16.Pages.Counter
import Evergreen.V16.Pages.Home_
import Evergreen.V16.Pages.Menu
import Evergreen.V16.Pages.NotFound_
import Evergreen.V16.Pages.PickVariant
import Evergreen.V16.Pages.Results


type Msg
    = Home_ Evergreen.V16.Pages.Home_.Msg
    | Counter Evergreen.V16.Pages.Counter.Msg
    | Menu Evergreen.V16.Pages.Menu.Msg
    | PickVariant Evergreen.V16.Pages.PickVariant.Msg
    | Results Evergreen.V16.Pages.Results.Msg
    | NotFound_ Evergreen.V16.Pages.NotFound_.Msg
