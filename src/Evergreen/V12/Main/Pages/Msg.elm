module Evergreen.V12.Main.Pages.Msg exposing (..)

import Evergreen.V12.Pages.Counter
import Evergreen.V12.Pages.Home_
import Evergreen.V12.Pages.Menu
import Evergreen.V12.Pages.NotFound_
import Evergreen.V12.Pages.PickVariant
import Evergreen.V12.Pages.Results


type Msg
    = Home_ Evergreen.V12.Pages.Home_.Msg
    | Counter Evergreen.V12.Pages.Counter.Msg
    | Menu Evergreen.V12.Pages.Menu.Msg
    | PickVariant Evergreen.V12.Pages.PickVariant.Msg
    | Results Evergreen.V12.Pages.Results.Msg
    | NotFound_ Evergreen.V12.Pages.NotFound_.Msg
