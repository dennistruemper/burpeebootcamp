module Evergreen.V12.Pages.Counter exposing (..)

import Time


type EMOMStatus
    = WaitingToStart
    | InProgress
    | Complete
    | Failed


type alias EMOMSettings =
    { startTime : Time.Posix
    , repsPerMinute : Int
    , totalRounds : Int
    , currentRound : Int
    , status : EMOMStatus
    , showSettings : Bool
    , currentTickTime : Time.Posix
    }


type SessionMode
    = Free
    | EMOM EMOMSettings
    | Workout
        { totalGoal : Int
        }


type alias Model =
    { currentReps : Int
    , overwriteRepGoal : Maybe Int
    , initialShowWelcomeModal : Bool
    , groundTouchesForCurrentRep : Int
    , sessionMode : Maybe SessionMode
    , isMysteryMode : Bool
    , redirectTime : Maybe Time.Posix
    }


type Msg
    = IncrementReps
    | ResetCounter
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime
    | ChangeToMenu
    | CloseWelcomeModal
    | SelectMode SessionMode
    | GotWorkoutGoal Int
    | ConfigureEMOM EMOMSettings
    | StartEMOM
    | EMOMStarted Time.Posix
    | EMOMTick Time.Posix
