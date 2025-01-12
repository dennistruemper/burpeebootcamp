module Evergreen.V8.Main.Pages.Model exposing (..)

import Evergreen.V8.Pages.Counter
import Evergreen.V8.Pages.Home_
import Evergreen.V8.Pages.Menu
import Evergreen.V8.Pages.NotFound_
import Evergreen.V8.Pages.PickVariant
import Evergreen.V8.Pages.Results


type Model
    = Home_ Evergreen.V8.Pages.Home_.Model
    | Counter Evergreen.V8.Pages.Counter.Model
    | Menu Evergreen.V8.Pages.Menu.Model
    | PickVariant Evergreen.V8.Pages.PickVariant.Model
    | Results Evergreen.V8.Pages.Results.Model
    | NotFound_ Evergreen.V8.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
