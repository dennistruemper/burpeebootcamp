module Main.Pages.Model exposing (Model(..))

import Pages.Home_
import Pages.Counter
import Pages.Menu
import Pages.PickVariant
import Pages.Results
import Pages.NotFound_
import View exposing (View)


type Model
    = Home_ Pages.Home_.Model
    | Counter Pages.Counter.Model
    | Menu Pages.Menu.Model
    | PickVariant Pages.PickVariant.Model
    | Results Pages.Results.Model
    | NotFound_ Pages.NotFound_.Model
    | Redirecting_
    | Loading_
