module Main.Pages.Model exposing (Model(..))

import Pages.Home_
import Pages.Counter
import Pages.PickVariant
import Pages.NotFound_
import View exposing (View)


type Model
    = Home_ Pages.Home_.Model
    | Counter Pages.Counter.Model
    | PickVariant Pages.PickVariant.Model
    | NotFound_ Pages.NotFound_.Model
    | Redirecting_
    | Loading_
