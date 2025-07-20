module Evergreen.V20.Pages.Counter.EMOM exposing (..)

import Time


type EMOMStatus
    = WaitingToStart
    | InProgress
    | Complete
    | Failed


type EMOMMode
    = FixedRounds
    | EndlessMode


type alias EMOMSettings =
    { startTime : Time.Posix
    , repsPerMinute : Int
    , totalRounds : Int
    , currentRound : Int
    , status : EMOMStatus
    , showSettings : Bool
    , currentTickTime : Time.Posix
    , mode : EMOMMode
    }
