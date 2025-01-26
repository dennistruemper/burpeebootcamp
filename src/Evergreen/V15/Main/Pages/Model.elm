module Evergreen.V15.Main.Pages.Model exposing (..)

import Evergreen.V15.Pages.Counter
import Evergreen.V15.Pages.Home_
import Evergreen.V15.Pages.Menu
import Evergreen.V15.Pages.NotFound_
import Evergreen.V15.Pages.PickVariant
import Evergreen.V15.Pages.Results


type Model
    = Home_ Evergreen.V15.Pages.Home_.Model
    | Counter Evergreen.V15.Pages.Counter.Model
    | Menu Evergreen.V15.Pages.Menu.Model
    | PickVariant Evergreen.V15.Pages.PickVariant.Model
    | Results Evergreen.V15.Pages.Results.Model
    | NotFound_ Evergreen.V15.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
