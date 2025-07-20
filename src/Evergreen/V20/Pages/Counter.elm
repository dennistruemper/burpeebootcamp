module Evergreen.V20.Pages.Counter exposing (..)

import Evergreen.V20.Pages.Counter.AMRAP
import Evergreen.V20.Pages.Counter.EMOM
import Time


type SessionMode
    = Free
    | EMOM Evergreen.V20.Pages.Counter.EMOM.EMOMSettings
    | Workout
        { totalGoal : Int
        }
    | AMRAP Evergreen.V20.Pages.Counter.AMRAP.AMRAPSettings


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
    , soundEnabled : Bool
    , lastWarningTime : Maybe Time.Posix
    }


type Msg
    = IncrementReps
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime
    | ChangeToMenu
    | CloseWelcomeModal
    | SelectMode SessionMode
    | GotWorkoutGoal Int
    | ConfigureEMOM Evergreen.V20.Pages.Counter.EMOM.EMOMSettings
    | StartEMOM
    | EMOMStarted Time.Posix
    | EMOMTick Time.Posix
    | DebounceComplete Time.Posix
    | ConfigureAMRAP Evergreen.V20.Pages.Counter.AMRAP.AMRAPSettings
    | StartAMRAP
    | AMRAPStarted Time.Posix
    | AMRAPTick Time.Posix
    | ToggleHelpModal
    | CloseHelpModal
    | ToggleSound
