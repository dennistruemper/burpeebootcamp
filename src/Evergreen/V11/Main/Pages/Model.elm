module Evergreen.V11.Main.Pages.Model exposing (..)

import Evergreen.V11.Pages.Counter
import Evergreen.V11.Pages.Home_
import Evergreen.V11.Pages.Menu
import Evergreen.V11.Pages.NotFound_
import Evergreen.V11.Pages.PickVariant
import Evergreen.V11.Pages.Results


type Model
    = Home_ Evergreen.V11.Pages.Home_.Model
    | Counter Evergreen.V11.Pages.Counter.Model
    | Menu Evergreen.V11.Pages.Menu.Model
    | PickVariant Evergreen.V11.Pages.PickVariant.Model
    | Results Evergreen.V11.Pages.Results.Model
    | NotFound_ Evergreen.V11.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
