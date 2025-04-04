module Evergreen.Migrate.V15 exposing (..)

{-| This migration file was automatically generated by the lamdera compiler.

It includes:

  - A migration for each of the 6 Lamdera core types that has changed
  - A function named `migrate_ModuleName_TypeName` for each changed/custom type

Expect to see:

  - `Unimplementеd` values as placeholders wherever I was unable to figure out a clear migration path for you
  - `@NOTICE` comments for things you should know about, i.e. new custom type constructors that won't get any
    value mappings from the old type by default

You can edit this file however you wish! It won't be generated again.

See <https://dashboard.lamdera.app/docs/evergreen> for more info.

-}

import Evergreen.V12.Burpee
import Evergreen.V12.Main
import Evergreen.V12.Main.Pages.Model
import Evergreen.V12.Main.Pages.Msg
import Evergreen.V12.Pages.Counter
import Evergreen.V12.Pages.Home_
import Evergreen.V12.Pages.Menu
import Evergreen.V12.Pages.NotFound_
import Evergreen.V12.Pages.PickVariant
import Evergreen.V12.Pages.Results
import Evergreen.V12.Route.Path
import Evergreen.V12.Shared
import Evergreen.V12.Shared.Model
import Evergreen.V12.Shared.Msg
import Evergreen.V12.Types
import Evergreen.V12.WorkoutResult
import Evergreen.V15.Burpee
import Evergreen.V15.Main
import Evergreen.V15.Main.Pages.Model
import Evergreen.V15.Main.Pages.Msg
import Evergreen.V15.Pages.Counter
import Evergreen.V15.Pages.Home_
import Evergreen.V15.Pages.Menu
import Evergreen.V15.Pages.NotFound_
import Evergreen.V15.Pages.PickVariant
import Evergreen.V15.Pages.Results
import Evergreen.V15.Route.Path
import Evergreen.V15.Shared
import Evergreen.V15.Shared.Model
import Evergreen.V15.Shared.Msg
import Evergreen.V15.Types
import Evergreen.V15.WorkoutResult
import Lamdera.Migrations exposing (..)
import List
import Maybe


frontendModel : Evergreen.V12.Types.FrontendModel -> ModelMigration Evergreen.V15.Types.FrontendModel Evergreen.V15.Types.FrontendMsg
frontendModel old =
    ModelMigrated ( migrate_Types_FrontendModel old, Cmd.none )


backendModel : Evergreen.V12.Types.BackendModel -> ModelMigration Evergreen.V15.Types.BackendModel Evergreen.V15.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V12.Types.FrontendMsg -> MsgMigration Evergreen.V15.Types.FrontendMsg Evergreen.V15.Types.FrontendMsg
frontendMsg old =
    MsgMigrated ( migrate_Types_FrontendMsg old, Cmd.none )


toBackend : Evergreen.V12.Types.ToBackend -> MsgMigration Evergreen.V15.Types.ToBackend Evergreen.V15.Types.BackendMsg
toBackend old =
    MsgUnchanged


backendMsg : Evergreen.V12.Types.BackendMsg -> MsgMigration Evergreen.V15.Types.BackendMsg Evergreen.V15.Types.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Evergreen.V12.Types.ToFrontend -> MsgMigration Evergreen.V15.Types.ToFrontend Evergreen.V15.Types.FrontendMsg
toFrontend old =
    MsgUnchanged


migrate_Types_FrontendModel : Evergreen.V12.Types.FrontendModel -> Evergreen.V15.Types.FrontendModel
migrate_Types_FrontendModel old =
    old |> migrate_Main_Model


migrate_Types_FrontendMsg : Evergreen.V12.Types.FrontendMsg -> Evergreen.V15.Types.FrontendMsg
migrate_Types_FrontendMsg old =
    old |> migrate_Main_Msg


migrate_Burpee_Burpee : Evergreen.V12.Burpee.Burpee -> Evergreen.V15.Burpee.Burpee
migrate_Burpee_Burpee old =
    case old of
        Evergreen.V12.Burpee.Burpee p0 ->
            Evergreen.V15.Burpee.Burpee
                { name = p0.name
                , angle = p0.angle |> migrate_Burpee_GroundAngle
                , groundPart = p0.groundPart |> migrate_Burpee_GroundPart
                , topPart = p0.topPart |> migrate_Burpee_TopPart
                }


migrate_Burpee_GroundAngle : Evergreen.V12.Burpee.GroundAngle -> Evergreen.V15.Burpee.GroundAngle
migrate_Burpee_GroundAngle old =
    case old of
        Evergreen.V12.Burpee.HipInclined ->
            Evergreen.V15.Burpee.HipInclined

        Evergreen.V12.Burpee.KneeInclined ->
            Evergreen.V15.Burpee.KneeInclined

        Evergreen.V12.Burpee.LittleInclined ->
            Evergreen.V15.Burpee.LittleInclined

        Evergreen.V12.Burpee.Flat ->
            Evergreen.V15.Burpee.Flat

        Evergreen.V12.Burpee.LittleDecline ->
            Evergreen.V15.Burpee.LittleDecline

        Evergreen.V12.Burpee.KneeDecline ->
            Evergreen.V15.Burpee.KneeDecline


migrate_Burpee_GroundPart : Evergreen.V12.Burpee.GroundPart -> Evergreen.V15.Burpee.GroundPart
migrate_Burpee_GroundPart old =
    case old of
        Evergreen.V12.Burpee.Plank ->
            Evergreen.V15.Burpee.Plank

        Evergreen.V12.Burpee.MountainClimbers p0 ->
            Evergreen.V15.Burpee.MountainClimbers p0

        Evergreen.V12.Burpee.Pushups p0 ->
            Evergreen.V15.Burpee.Pushups p0

        Evergreen.V12.Burpee.NavySeals p0 ->
            Evergreen.V15.Burpee.NavySeals p0


migrate_Burpee_TopPart : Evergreen.V12.Burpee.TopPart -> Evergreen.V15.Burpee.TopPart
migrate_Burpee_TopPart old =
    case old of
        Evergreen.V12.Burpee.Jump ->
            Evergreen.V15.Burpee.Jump

        Evergreen.V12.Burpee.TuckJump ->
            Evergreen.V15.Burpee.TuckJump

        Evergreen.V12.Burpee.KneeRaise ->
            Evergreen.V15.Burpee.KneeRaise

        Evergreen.V12.Burpee.JumpingJack ->
            Evergreen.V15.Burpee.JumpingJack

        Evergreen.V12.Burpee.BoxJump ->
            Evergreen.V15.Burpee.BoxJump

        Evergreen.V12.Burpee.PullUp ->
            Evergreen.V15.Burpee.PullUp

        Evergreen.V12.Burpee.NoOp ->
            Evergreen.V15.Burpee.NoOp


migrate_Main_Model : Evergreen.V12.Main.Model -> Evergreen.V15.Main.Model
migrate_Main_Model old =
    { key = old.key
    , url = old.url
    , page = old.page |> migrate_Main_Pages_Model_Model
    , layout = old.layout
    , shared = old.shared |> migrate_Shared_Model
    }


migrate_Main_Msg : Evergreen.V12.Main.Msg -> Evergreen.V15.Main.Msg
migrate_Main_Msg old =
    case old of
        Evergreen.V12.Main.UrlRequested p0 ->
            Evergreen.V15.Main.UrlRequested p0

        Evergreen.V12.Main.UrlChanged p0 ->
            Evergreen.V15.Main.UrlChanged p0

        Evergreen.V12.Main.Page p0 ->
            Evergreen.V15.Main.Page (p0 |> migrate_Main_Pages_Msg_Msg)

        Evergreen.V12.Main.Layout p0 ->
            Evergreen.V15.Main.Layout p0

        Evergreen.V12.Main.Shared p0 ->
            Evergreen.V15.Main.Shared (p0 |> migrate_Shared_Msg)

        Evergreen.V12.Main.Batch p0 ->
            Evergreen.V15.Main.Batch (p0 |> List.map migrate_Main_Msg)


migrate_Main_Pages_Model_Model : Evergreen.V12.Main.Pages.Model.Model -> Evergreen.V15.Main.Pages.Model.Model
migrate_Main_Pages_Model_Model old =
    case old of
        Evergreen.V12.Main.Pages.Model.Home_ p0 ->
            Evergreen.V15.Main.Pages.Model.Home_ (p0 |> migrate_Pages_Home__Model)

        Evergreen.V12.Main.Pages.Model.Counter p0 ->
            Evergreen.V15.Main.Pages.Model.Counter (p0 |> migrate_Pages_Counter_Model)

        Evergreen.V12.Main.Pages.Model.Menu p0 ->
            Evergreen.V15.Main.Pages.Model.Menu (p0 |> migrate_Pages_Menu_Model)

        Evergreen.V12.Main.Pages.Model.PickVariant p0 ->
            Evergreen.V15.Main.Pages.Model.PickVariant (p0 |> migrate_Pages_PickVariant_Model)

        Evergreen.V12.Main.Pages.Model.Results p0 ->
            Evergreen.V15.Main.Pages.Model.Results (p0 |> migrate_Pages_Results_Model)

        Evergreen.V12.Main.Pages.Model.NotFound_ p0 ->
            Evergreen.V15.Main.Pages.Model.NotFound_ (p0 |> migrate_Pages_NotFound__Model)

        Evergreen.V12.Main.Pages.Model.Redirecting_ ->
            Evergreen.V15.Main.Pages.Model.Redirecting_

        Evergreen.V12.Main.Pages.Model.Loading_ ->
            Evergreen.V15.Main.Pages.Model.Loading_


migrate_Main_Pages_Msg_Msg : Evergreen.V12.Main.Pages.Msg.Msg -> Evergreen.V15.Main.Pages.Msg.Msg
migrate_Main_Pages_Msg_Msg old =
    case old of
        Evergreen.V12.Main.Pages.Msg.Home_ p0 ->
            Evergreen.V15.Main.Pages.Msg.Home_ (p0 |> migrate_Pages_Home__Msg)

        Evergreen.V12.Main.Pages.Msg.Counter p0 ->
            Evergreen.V15.Main.Pages.Msg.Counter (p0 |> migrate_Pages_Counter_Msg)

        Evergreen.V12.Main.Pages.Msg.Menu p0 ->
            Evergreen.V15.Main.Pages.Msg.Menu (p0 |> migrate_Pages_Menu_Msg)

        Evergreen.V12.Main.Pages.Msg.PickVariant p0 ->
            Evergreen.V15.Main.Pages.Msg.PickVariant (p0 |> migrate_Pages_PickVariant_Msg)

        Evergreen.V12.Main.Pages.Msg.Results p0 ->
            Evergreen.V15.Main.Pages.Msg.Results (p0 |> migrate_Pages_Results_Msg)

        Evergreen.V12.Main.Pages.Msg.NotFound_ p0 ->
            Evergreen.V15.Main.Pages.Msg.NotFound_ (p0 |> migrate_Pages_NotFound__Msg)


migrate_Pages_Counter_EMOMSettings : Evergreen.V12.Pages.Counter.EMOMSettings -> Evergreen.V15.Pages.Counter.EMOMSettings
migrate_Pages_Counter_EMOMSettings old =
    { startTime = old.startTime
    , repsPerMinute = old.repsPerMinute
    , totalRounds = old.totalRounds
    , currentRound = old.currentRound
    , status = old.status |> migrate_Pages_Counter_EMOMStatus
    , showSettings = old.showSettings
    , currentTickTime = old.currentTickTime
    }


migrate_Pages_Counter_EMOMStatus : Evergreen.V12.Pages.Counter.EMOMStatus -> Evergreen.V15.Pages.Counter.EMOMStatus
migrate_Pages_Counter_EMOMStatus old =
    case old of
        Evergreen.V12.Pages.Counter.WaitingToStart ->
            Evergreen.V15.Pages.Counter.WaitingToStart

        Evergreen.V12.Pages.Counter.InProgress ->
            Evergreen.V15.Pages.Counter.InProgress

        Evergreen.V12.Pages.Counter.Complete ->
            Evergreen.V15.Pages.Counter.Complete

        Evergreen.V12.Pages.Counter.Failed ->
            Evergreen.V15.Pages.Counter.Failed


migrate_Pages_Counter_Model : Evergreen.V12.Pages.Counter.Model -> Evergreen.V15.Pages.Counter.Model
migrate_Pages_Counter_Model old =
    { currentReps = old.currentReps
    , overwriteRepGoal = old.overwriteRepGoal
    , initialShowWelcomeModal = old.initialShowWelcomeModal
    , groundTouchesForCurrentRep = old.groundTouchesForCurrentRep
    , sessionMode = old.sessionMode |> Maybe.map migrate_Pages_Counter_SessionMode
    , isMysteryMode = old.isMysteryMode
    , redirectTime = old.redirectTime
    , isDebouncing = False
    }


migrate_Pages_Counter_Msg : Evergreen.V12.Pages.Counter.Msg -> Evergreen.V15.Pages.Counter.Msg
migrate_Pages_Counter_Msg old =
    case old of
        Evergreen.V12.Pages.Counter.IncrementReps ->
            Evergreen.V15.Pages.Counter.IncrementReps

        Evergreen.V12.Pages.Counter.ResetCounter ->
            Evergreen.V15.Pages.Counter.ResetCounter

        Evergreen.V12.Pages.Counter.GotWorkoutFinishedTime p0 ->
            Evergreen.V15.Pages.Counter.GotWorkoutFinishedTime p0

        Evergreen.V12.Pages.Counter.GetWorkoutFinishedTime ->
            Evergreen.V15.Pages.Counter.GetWorkoutFinishedTime

        Evergreen.V12.Pages.Counter.ChangeToMenu ->
            Evergreen.V15.Pages.Counter.ChangeToMenu

        Evergreen.V12.Pages.Counter.CloseWelcomeModal ->
            Evergreen.V15.Pages.Counter.CloseWelcomeModal

        Evergreen.V12.Pages.Counter.SelectMode p0 ->
            Evergreen.V15.Pages.Counter.SelectMode (p0 |> migrate_Pages_Counter_SessionMode)

        Evergreen.V12.Pages.Counter.GotWorkoutGoal p0 ->
            Evergreen.V15.Pages.Counter.GotWorkoutGoal p0

        Evergreen.V12.Pages.Counter.ConfigureEMOM p0 ->
            Evergreen.V15.Pages.Counter.ConfigureEMOM (p0 |> migrate_Pages_Counter_EMOMSettings)

        Evergreen.V12.Pages.Counter.StartEMOM ->
            Evergreen.V15.Pages.Counter.StartEMOM

        Evergreen.V12.Pages.Counter.EMOMStarted p0 ->
            Evergreen.V15.Pages.Counter.EMOMStarted p0

        Evergreen.V12.Pages.Counter.EMOMTick p0 ->
            Evergreen.V15.Pages.Counter.EMOMTick p0


migrate_Pages_Counter_SessionMode : Evergreen.V12.Pages.Counter.SessionMode -> Evergreen.V15.Pages.Counter.SessionMode
migrate_Pages_Counter_SessionMode old =
    case old of
        Evergreen.V12.Pages.Counter.Free ->
            Evergreen.V15.Pages.Counter.Free

        Evergreen.V12.Pages.Counter.EMOM p0 ->
            Evergreen.V15.Pages.Counter.EMOM (p0 |> migrate_Pages_Counter_EMOMSettings)

        Evergreen.V12.Pages.Counter.Workout p0 ->
            Evergreen.V15.Pages.Counter.Workout p0


migrate_Pages_Home__Model : Evergreen.V12.Pages.Home_.Model -> Evergreen.V15.Pages.Home_.Model
migrate_Pages_Home__Model old =
    old


migrate_Pages_Home__Msg : Evergreen.V12.Pages.Home_.Msg -> Evergreen.V15.Pages.Home_.Msg
migrate_Pages_Home__Msg old =
    case old of
        Evergreen.V12.Pages.Home_.Redirect ->
            Evergreen.V15.Pages.Home_.Redirect


migrate_Pages_Menu_Model : Evergreen.V12.Pages.Menu.Model -> Evergreen.V15.Pages.Menu.Model
migrate_Pages_Menu_Model old =
    old


migrate_Pages_Menu_Msg : Evergreen.V12.Pages.Menu.Msg -> Evergreen.V15.Pages.Menu.Msg
migrate_Pages_Menu_Msg old =
    case old of
        Evergreen.V12.Pages.Menu.NavigateTo p0 ->
            Evergreen.V15.Pages.Menu.NavigateTo (p0 |> migrate_Route_Path_Path)


migrate_Pages_NotFound__Model : Evergreen.V12.Pages.NotFound_.Model -> Evergreen.V15.Pages.NotFound_.Model
migrate_Pages_NotFound__Model old =
    old


migrate_Pages_NotFound__Msg : Evergreen.V12.Pages.NotFound_.Msg -> Evergreen.V15.Pages.NotFound_.Msg
migrate_Pages_NotFound__Msg old =
    case old of
        Evergreen.V12.Pages.NotFound_.NoOp ->
            Evergreen.V15.Pages.NotFound_.NoOp


migrate_Pages_PickVariant_Model : Evergreen.V12.Pages.PickVariant.Model -> Evergreen.V15.Pages.PickVariant.Model
migrate_Pages_PickVariant_Model old =
    { variants = old.variants |> List.map migrate_Burpee_Burpee
    , selectedVariant = old.selectedVariant |> Maybe.map migrate_Burpee_Burpee
    , goalInput = old.goalInput
    , first = old.first
    }


migrate_Pages_PickVariant_Msg : Evergreen.V12.Pages.PickVariant.Msg -> Evergreen.V15.Pages.PickVariant.Msg
migrate_Pages_PickVariant_Msg old =
    case old of
        Evergreen.V12.Pages.PickVariant.PickedVariant p0 ->
            Evergreen.V15.Pages.PickVariant.PickedVariant (p0 |> migrate_Burpee_Burpee)

        Evergreen.V12.Pages.PickVariant.UpdateGoalInput p0 ->
            Evergreen.V15.Pages.PickVariant.UpdateGoalInput p0

        Evergreen.V12.Pages.PickVariant.StartWorkout ->
            Evergreen.V15.Pages.PickVariant.StartWorkout

        Evergreen.V12.Pages.PickVariant.NavigateBack ->
            Evergreen.V15.Pages.PickVariant.NavigateBack

        Evergreen.V12.Pages.PickVariant.BackToSelection ->
            Evergreen.V15.Pages.PickVariant.BackToSelection


migrate_Pages_Results_Model : Evergreen.V12.Pages.Results.Model -> Evergreen.V15.Pages.Results.Model
migrate_Pages_Results_Model old =
    old


migrate_Pages_Results_Msg : Evergreen.V12.Pages.Results.Msg -> Evergreen.V15.Pages.Results.Msg
migrate_Pages_Results_Msg old =
    case old of
        Evergreen.V12.Pages.Results.GotCurrentTime p0 ->
            Evergreen.V15.Pages.Results.GotCurrentTime p0

        Evergreen.V12.Pages.Results.UpdateDaysToShow p0 ->
            Evergreen.V15.Pages.Results.UpdateDaysToShow p0

        Evergreen.V12.Pages.Results.NavigateToMenu ->
            Evergreen.V15.Pages.Results.NavigateToMenu

        Evergreen.V12.Pages.Results.TogglePopover p0 ->
            Evergreen.V15.Pages.Results.TogglePopover p0

        Evergreen.V12.Pages.Results.NoOp ->
            Evergreen.V15.Pages.Results.NoOp

        Evergreen.V12.Pages.Results.CloseSlider ->
            Evergreen.V15.Pages.Results.CloseSlider


migrate_Route_Path_Path : Evergreen.V12.Route.Path.Path -> Evergreen.V15.Route.Path.Path
migrate_Route_Path_Path old =
    case old of
        Evergreen.V12.Route.Path.Home_ ->
            Evergreen.V15.Route.Path.Home_

        Evergreen.V12.Route.Path.Counter ->
            Evergreen.V15.Route.Path.Counter

        Evergreen.V12.Route.Path.Menu ->
            Evergreen.V15.Route.Path.Menu

        Evergreen.V12.Route.Path.PickVariant ->
            Evergreen.V15.Route.Path.PickVariant

        Evergreen.V12.Route.Path.Results ->
            Evergreen.V15.Route.Path.Results

        Evergreen.V12.Route.Path.NotFound_ ->
            Evergreen.V15.Route.Path.NotFound_


migrate_Shared_Model : Evergreen.V12.Shared.Model -> Evergreen.V15.Shared.Model
migrate_Shared_Model old =
    old |> migrate_Shared_Model_Model


migrate_Shared_Model_Model : Evergreen.V12.Shared.Model.Model -> Evergreen.V15.Shared.Model.Model
migrate_Shared_Model_Model old =
    { currentBurpee = old.currentBurpee |> Maybe.map migrate_Burpee_Burpee
    , workoutHistory = old.workoutHistory |> List.map migrate_WorkoutResult_WorkoutResult
    , initializing = old.initializing
    , currentTime = old.currentTime
    , version = old.version
    }


migrate_Shared_Msg : Evergreen.V12.Shared.Msg -> Evergreen.V15.Shared.Msg
migrate_Shared_Msg old =
    old |> migrate_Shared_Msg_Msg


migrate_Shared_Msg_Msg : Evergreen.V12.Shared.Msg.Msg -> Evergreen.V15.Shared.Msg.Msg
migrate_Shared_Msg_Msg old =
    case old of
        Evergreen.V12.Shared.Msg.BurpeePicked p0 ->
            Evergreen.V15.Shared.Msg.BurpeePicked (p0 |> migrate_Burpee_Burpee)

        Evergreen.V12.Shared.Msg.StoreWorkoutResult p0 ->
            Evergreen.V15.Shared.Msg.StoreWorkoutResult (p0 |> migrate_WorkoutResult_WorkoutResult)

        Evergreen.V12.Shared.Msg.GotPortMessage p0 ->
            Evergreen.V15.Shared.Msg.GotPortMessage p0

        Evergreen.V12.Shared.Msg.GotTimeForRepGoalCalculation p0 ->
            Evergreen.V15.Shared.Msg.GotTimeForRepGoalCalculation p0

        Evergreen.V12.Shared.Msg.GotTime p0 ->
            Evergreen.V15.Shared.Msg.GotTime p0

        Evergreen.V12.Shared.Msg.GotTimeForFakedata p0 ->
            Evergreen.V15.Shared.Msg.GotTimeForFakedata p0

        Evergreen.V12.Shared.Msg.NoOp ->
            Evergreen.V15.Shared.Msg.NoOp


migrate_WorkoutResult_WorkoutResult : Evergreen.V12.WorkoutResult.WorkoutResult -> Evergreen.V15.WorkoutResult.WorkoutResult
migrate_WorkoutResult_WorkoutResult old =
    { reps = old.reps
    , repGoal = old.repGoal
    , burpee = old.burpee |> migrate_Burpee_Burpee
    , timestamp = old.timestamp
    }
