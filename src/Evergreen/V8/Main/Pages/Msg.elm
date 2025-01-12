module Evergreen.V8.Main.Pages.Msg exposing (..)

import Evergreen.V8.Pages.Counter
import Evergreen.V8.Pages.Home_
import Evergreen.V8.Pages.Menu
import Evergreen.V8.Pages.NotFound_
import Evergreen.V8.Pages.PickVariant
import Evergreen.V8.Pages.Results


type Msg
    = Home_ Evergreen.V8.Pages.Home_.Msg
    | Counter Evergreen.V8.Pages.Counter.Msg
    | Menu Evergreen.V8.Pages.Menu.Msg
    | PickVariant Evergreen.V8.Pages.PickVariant.Msg
    | Results Evergreen.V8.Pages.Results.Msg
    | NotFound_ Evergreen.V8.Pages.NotFound_.Msg
