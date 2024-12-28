module Evergreen.V2.Main.Pages.Model exposing (..)

import Evergreen.V2.Pages.Counter
import Evergreen.V2.Pages.Home_
import Evergreen.V2.Pages.NotFound_


type Model
    = Home_ Evergreen.V2.Pages.Home_.Model
    | Counter Evergreen.V2.Pages.Counter.Model
    | NotFound_ Evergreen.V2.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
