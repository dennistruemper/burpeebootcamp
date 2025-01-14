module Evergreen.V9.Main.Pages.Model exposing (..)

import Evergreen.V9.Pages.Counter
import Evergreen.V9.Pages.Home_
import Evergreen.V9.Pages.Menu
import Evergreen.V9.Pages.NotFound_
import Evergreen.V9.Pages.PickVariant
import Evergreen.V9.Pages.Results


type Model
    = Home_ Evergreen.V9.Pages.Home_.Model
    | Counter Evergreen.V9.Pages.Counter.Model
    | Menu Evergreen.V9.Pages.Menu.Model
    | PickVariant Evergreen.V9.Pages.PickVariant.Model
    | Results Evergreen.V9.Pages.Results.Model
    | NotFound_ Evergreen.V9.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
