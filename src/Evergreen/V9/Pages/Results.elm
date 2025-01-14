module Evergreen.V9.Pages.Results exposing (..)

import Time


type alias Model =
    { currentTime : Time.Posix
    , selectedDate : Maybe Time.Posix
    , daysToShow : Int
    , popoverDay : Maybe Time.Posix
    }


type Msg
    = GotCurrentTime Time.Posix
    | SelectDate (Maybe Time.Posix)
    | UpdateDaysToShow Int
    | NavigateToMenu
    | TogglePopover (Maybe Time.Posix)
    | NoOp
    | CloseSlider
