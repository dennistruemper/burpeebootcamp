module Evergreen.V12.Main.Pages.Model exposing (..)

import Evergreen.V12.Pages.Counter
import Evergreen.V12.Pages.Home_
import Evergreen.V12.Pages.Menu
import Evergreen.V12.Pages.NotFound_
import Evergreen.V12.Pages.PickVariant
import Evergreen.V12.Pages.Results


type Model
    = Home_ Evergreen.V12.Pages.Home_.Model
    | Counter Evergreen.V12.Pages.Counter.Model
    | Menu Evergreen.V12.Pages.Menu.Model
    | PickVariant Evergreen.V12.Pages.PickVariant.Model
    | Results Evergreen.V12.Pages.Results.Model
    | NotFound_ Evergreen.V12.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
