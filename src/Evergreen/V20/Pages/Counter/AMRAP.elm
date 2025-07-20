module Evergreen.V20.Pages.Counter.AMRAP exposing (..)

import Time


type AMRAPStatus
    = NotStarted
    | Running
    | Finished


type alias AMRAPSettings =
    { duration : Int
    , startTime : Time.Posix
    , currentTime : Time.Posix
    , status : AMRAPStatus
    , showSettings : Bool
    , previousBest : Maybe Int
    }
