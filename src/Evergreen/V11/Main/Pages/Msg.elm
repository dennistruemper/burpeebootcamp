module Evergreen.V11.Main.Pages.Msg exposing (..)

import Evergreen.V11.Pages.Counter
import Evergreen.V11.Pages.Home_
import Evergreen.V11.Pages.Menu
import Evergreen.V11.Pages.NotFound_
import Evergreen.V11.Pages.PickVariant
import Evergreen.V11.Pages.Results


type Msg
    = Home_ Evergreen.V11.Pages.Home_.Msg
    | Counter Evergreen.V11.Pages.Counter.Msg
    | Menu Evergreen.V11.Pages.Menu.Msg
    | PickVariant Evergreen.V11.Pages.PickVariant.Msg
    | Results Evergreen.V11.Pages.Results.Msg
    | NotFound_ Evergreen.V11.Pages.NotFound_.Msg
