module Evergreen.V3.Main.Pages.Model exposing (..)

import Evergreen.V3.Pages.Counter
import Evergreen.V3.Pages.Home_
import Evergreen.V3.Pages.NotFound_
import Evergreen.V3.Pages.PickVariant


type Model
    = Home_ Evergreen.V3.Pages.Home_.Model
    | Counter Evergreen.V3.Pages.Counter.Model
    | PickVariant Evergreen.V3.Pages.PickVariant.Model
    | NotFound_ Evergreen.V3.Pages.NotFound_.Model
    | Redirecting_
    | Loading_
