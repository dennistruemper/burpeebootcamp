module Evergreen.V20.Main.Pages.Model exposing (..)

import Evergreen.V20.Pages.Counter
import Evergreen.V20.Pages.Home_
import Evergreen.V20.Pages.Menu
import Evergreen.V20.Pages.NotFound_
import Evergreen.V20.Pages.PickVariant
import Evergreen.V20.Pages.Results


type Model
    = Home_ Evergreen.V20.Pages.Home_.Model
    | Counter Evergreen.V20.Pages.Counter.Model
    | Menu Evergreen.V20.Pages.Menu.Model
    | PickVariant Evergreen.V20.Pages.PickVariant.Model
    | Results Evergreen.V20.Pages.Results.Model
    | NotFound_ Evergreen.V20.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
