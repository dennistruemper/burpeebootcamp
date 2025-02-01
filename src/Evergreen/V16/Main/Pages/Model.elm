module Evergreen.V16.Main.Pages.Model exposing (..)

import Evergreen.V16.Pages.Counter
import Evergreen.V16.Pages.Home_
import Evergreen.V16.Pages.Menu
import Evergreen.V16.Pages.NotFound_
import Evergreen.V16.Pages.PickVariant
import Evergreen.V16.Pages.Results


type Model
    = Home_ Evergreen.V16.Pages.Home_.Model
    | Counter Evergreen.V16.Pages.Counter.Model
    | Menu Evergreen.V16.Pages.Menu.Model
    | PickVariant Evergreen.V16.Pages.PickVariant.Model
    | Results Evergreen.V16.Pages.Results.Model
    | NotFound_ Evergreen.V16.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
