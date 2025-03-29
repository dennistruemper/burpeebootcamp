module Evergreen.V19.Main.Pages.Model exposing (..)

import Evergreen.V19.Pages.Counter
import Evergreen.V19.Pages.Home_
import Evergreen.V19.Pages.Menu
import Evergreen.V19.Pages.NotFound_
import Evergreen.V19.Pages.PickVariant
import Evergreen.V19.Pages.Results


type Model
    = Home_ Evergreen.V19.Pages.Home_.Model
    | Counter Evergreen.V19.Pages.Counter.Model
    | Menu Evergreen.V19.Pages.Menu.Model
    | PickVariant Evergreen.V19.Pages.PickVariant.Model
    | Results Evergreen.V19.Pages.Results.Model
    | NotFound_ Evergreen.V19.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
