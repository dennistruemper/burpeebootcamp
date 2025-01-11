module Main.Pages.Msg exposing (Msg(..))

import Pages.Home_
import Pages.Counter
import Pages.Menu
import Pages.PickVariant
import Pages.Results
import Pages.NotFound_


type Msg
    = Home_ Pages.Home_.Msg
    | Counter Pages.Counter.Msg
    | Menu Pages.Menu.Msg
    | PickVariant Pages.PickVariant.Msg
    | Results Pages.Results.Msg
    | NotFound_ Pages.NotFound_.Msg
