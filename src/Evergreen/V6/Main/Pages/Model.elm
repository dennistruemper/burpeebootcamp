module Evergreen.V6.Main.Pages.Model exposing (..)

import Evergreen.V6.Pages.Counter
import Evergreen.V6.Pages.Home_
import Evergreen.V6.Pages.Menu
import Evergreen.V6.Pages.NotFound_
import Evergreen.V6.Pages.PickVariant
import Evergreen.V6.Pages.Results


type Model
    = Home_ Evergreen.V6.Pages.Home_.Model
    | Counter Evergreen.V6.Pages.Counter.Model
    | Menu Evergreen.V6.Pages.Menu.Model
    | PickVariant Evergreen.V6.Pages.PickVariant.Model
    | Results Evergreen.V6.Pages.Results.Model
    | NotFound_ Evergreen.V6.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
