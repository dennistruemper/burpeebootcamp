module Evergreen.V16.Pages.Counter exposing (..)

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


type SessionMode
    = Free
    | EMOM EMOMSettings
    | Workout
        { totalGoal : Int
        }
    | AMRAP AMRAPSettings


type alias Model =
    { currentReps : Int
    , overwriteRepGoal : Maybe Int
    , initialShowWelcomeModal : Bool
    , groundTouchesForCurrentRep : Int
    , sessionMode : Maybe SessionMode
    , isMysteryMode : Bool
    , redirectTime : Maybe Time.Posix
    , isDebouncing : Bool
    , showHelpModal : Bool
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
    | DebounceComplete Time.Posix
    | ConfigureAMRAP AMRAPSettings
    | StartAMRAP
    | AMRAPStarted Time.Posix
    | AMRAPTick Time.Posix
    | ToggleHelpModal
    | CloseHelpModal
