module Pages.Counter exposing
    ( Model
    , Msg(..)
    , SessionMode(..)
    , page
    )

import Burpee
import Dict
import Effect exposing (Effect)
import Html exposing (Html, br, button, details, div, h1, h3, h4, img, li, p, span, summary, text, ul)
import Html.Attributes exposing (alt, class, classList, src)
import Html.Events exposing (onClick)
import Page exposing (Page)
import Pages.Counter.AMRAP as AMRAP
import Pages.Counter.EMOM as EMOM
import Route exposing (Route)
import Route.Path
import Session.Goal
import Shared
import Sound
import Time
import View exposing (View)
import WorkoutResult


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init shared route
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type SessionMode
    = Free
    | EMOM EMOM.EMOMSettings
    | Workout { totalGoal : Int }
    | AMRAP AMRAP.AMRAPSettings


type Msg
    = IncrementReps
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime
    | ChangeToMenu
    | CloseWelcomeModal
    | SelectMode SessionMode
    | GotWorkoutGoal Int
    | ConfigureEMOM EMOM.EMOMSettings
    | StartEMOM
    | EMOMStarted Time.Posix
    | EMOMTick Time.Posix
    | DebounceComplete Time.Posix
    | ConfigureAMRAP AMRAP.AMRAPSettings
    | StartAMRAP
    | AMRAPStarted Time.Posix
    | AMRAPTick Time.Posix
    | ToggleHelpModal
    | CloseHelpModal
    | ToggleSound


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
    , lastWarningTime : Maybe Time.Posix -- Add this to track when we last played warning
    }


init : Shared.Model -> Route () -> () -> ( Model, Effect Msg )
init shared route _ =
    ( { currentReps = 0
      , overwriteRepGoal = Dict.get "repGoal" route.query |> Maybe.map String.toInt |> Maybe.withDefault Nothing
      , initialShowWelcomeModal = List.isEmpty shared.workoutHistory
      , groundTouchesForCurrentRep = 0
      , sessionMode = Nothing
      , isMysteryMode = False
      , redirectTime = Nothing
      , isDebouncing = False
      , showHelpModal = False
      , soundEnabled = True
      , lastWarningTime = Nothing -- Initialize warning time
      }
    , Effect.none
    )



-- UPDATE


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        IncrementReps ->
            if model.isDebouncing then
                ( model, Effect.none )

            else
                case model.sessionMode of
                    Just (AMRAP settings) ->
                        if settings.status == AMRAP.Finished then
                            ( model, Effect.none )

                        else
                            incrementReps shared model

                    _ ->
                        incrementReps shared model

        GetWorkoutFinishedTime ->
            ( model
            , Effect.getTime GotWorkoutFinishedTime
            )

        GotWorkoutFinishedTime time ->
            let
                sessionType : Maybe WorkoutResult.StoredSessionType
                sessionType =
                    case model.sessionMode of
                        Just (Workout _) ->
                            Just WorkoutResult.StoredWorkout

                        Just (EMOM _) ->
                            Just WorkoutResult.StoredEMOM

                        Just (AMRAP settings) ->
                            Just (WorkoutResult.StoredAMRAP { duration = settings.duration })

                        _ ->
                            Just WorkoutResult.StoredFree
            in
            ( { model | redirectTime = Nothing }
            , Effect.batch
                [ Effect.storeWorkoutResult
                    { reps = model.currentReps
                    , burpee = Maybe.withDefault Burpee.default shared.currentBurpee
                    , timestamp = time
                    , repGoal =
                        Just
                            (Session.Goal.calculateNextGoal
                                { lastSessions = shared.workoutHistory
                                , currentTime = shared.currentTime
                                , timeZone = shared.timeZone
                                }
                                model.overwriteRepGoal
                            )
                    , sessionType = sessionType
                    }
                , Effect.batch [ Effect.replaceRoutePath Route.Path.Results ]
                ]
            )

        ChangeToMenu ->
            ( model
            , Effect.replaceRoutePath Route.Path.Menu
            )

        CloseWelcomeModal ->
            ( { model | initialShowWelcomeModal = False }
            , Effect.none
            )

        SelectMode mode ->
            case mode of
                Workout _ ->
                    ( model
                    , Effect.getRandom
                        (Session.Goal.calculateWorkoutGoal
                            { lastSessions = shared.workoutHistory, currentTime = shared.currentTime, timeZone = shared.timeZone }
                            model.overwriteRepGoal
                        )
                        GotWorkoutGoal
                    )

                EMOM _ ->
                    let
                        repGoal : Int
                        repGoal =
                            Session.Goal.calculateNextGoal
                                { lastSessions = shared.workoutHistory
                                , currentTime = shared.currentTime
                                , timeZone = shared.timeZone
                                }
                                model.overwriteRepGoal
                    in
                    ( { model
                        | sessionMode = Just (EMOM (EMOM.defaultSettings repGoal))
                        , currentReps = 0
                      }
                    , Effect.none
                    )

                Free ->
                    ( { model | sessionMode = Just Free }
                    , Effect.none
                    )

                AMRAP _ ->
                    let
                        defaultSettings : AMRAP.AMRAPSettings
                        defaultSettings =
                            AMRAP.defaultSettings

                        previousBest : Maybe Int
                        previousBest =
                            findBestAMRAPScore shared.workoutHistory defaultSettings.duration
                    in
                    ( { model
                        | sessionMode =
                            Just
                                (AMRAP
                                    { defaultSettings | previousBest = previousBest }
                                )
                      }
                    , Effect.none
                    )

        GotWorkoutGoal goal ->
            ( { model | sessionMode = Just (Workout { totalGoal = goal }) }
            , Effect.none
            )

        EMOMTick newTime ->
            case model.sessionMode of
                Just (EMOM settings) ->
                    if settings.status == EMOM.WaitingToStart then
                        ( model, Effect.none )

                    else
                        let
                            elapsedTime : Int
                            elapsedTime =
                                Time.posixToMillis newTime - Time.posixToMillis settings.startTime

                            currentMinute : Int
                            currentMinute =
                                elapsedTime // 60000

                            isNewMinute : Bool
                            isNewMinute =
                                currentMinute + 1 > settings.currentRound

                            repsInCurrentRound : Int
                            repsInCurrentRound =
                                model.currentReps - (settings.currentRound - 1) * settings.repsPerMinute

                            isFailed : Bool
                            isFailed =
                                isNewMinute && repsInCurrentRound < settings.repsPerMinute

                            isComplete : Bool
                            isComplete =
                                case settings.mode of
                                    EMOM.FixedRounds ->
                                        settings.currentRound > settings.totalRounds

                                    EMOM.EndlessMode ->
                                        False

                            -- Use the reusable helper function
                            shouldPlayWarning : Bool
                            shouldPlayWarning =
                                EMOM.shouldPlayTimerWarning
                                    { currentReps = model.currentReps, lastWarningTime = model.lastWarningTime }
                                    settings
                                    newTime

                            newSettings : EMOM.EMOMSettings
                            newSettings =
                                if isFailed && settings.mode == EMOM.EndlessMode then
                                    { settings | status = EMOM.Failed, currentTickTime = newTime }

                                else if isComplete then
                                    { settings | status = EMOM.Complete, currentTickTime = newTime }

                                else if isNewMinute then
                                    { settings
                                        | currentRound = settings.currentRound + 1
                                        , currentTickTime = newTime
                                    }

                                else
                                    { settings | currentTickTime = newTime }
                        in
                        ( { model
                            | sessionMode = Just (EMOM newSettings)
                            , lastWarningTime =
                                if shouldPlayWarning then
                                    Just newTime

                                else
                                    model.lastWarningTime
                          }
                        , if isFailed || isComplete then
                            Effect.batch
                                [ Effect.getTime GotWorkoutFinishedTime
                                , Effect.playSound Sound.WorkoutComplete
                                ]

                          else if shouldPlayWarning then
                            Effect.playSound Sound.TimerWarning

                          else
                            Effect.none
                        )

                _ ->
                    ( model, Effect.none )

        StartEMOM ->
            ( model, Effect.getTime EMOMStarted )

        EMOMStarted time ->
            case model.sessionMode of
                Just (EMOM settings) ->
                    ( { model
                        | sessionMode =
                            Just (EMOM { settings | showSettings = False, status = EMOM.InProgress, startTime = time })
                        , currentReps = 0
                      }
                    , Effect.none
                    )

                Nothing ->
                    let
                        emomSetting : EMOM.EMOMSettings
                        emomSetting =
                            EMOM.defaultSettings
                                (Session.Goal.calculateNextGoal
                                    { lastSessions = shared.workoutHistory, currentTime = shared.currentTime, timeZone = shared.timeZone }
                                    model.overwriteRepGoal
                                )
                    in
                    ( { model
                        | sessionMode = Just (EMOM { emomSetting | startTime = time })
                        , currentReps = 0
                      }
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        ConfigureEMOM settings ->
            ( { model | sessionMode = Just (EMOM settings) }, Effect.none )

        DebounceComplete time ->
            let
                isDebouncing : Bool
                isDebouncing =
                    Time.posixToMillis time == 0
            in
            ( { model | isDebouncing = isDebouncing }
            , Effect.none
            )

        ConfigureAMRAP settings ->
            case model.sessionMode of
                Just (AMRAP currentSettings) ->
                    -- If we're already in AMRAP mode with settings open, preserve the showSettings state
                    ( { model | sessionMode = Just (AMRAP { settings | showSettings = currentSettings.showSettings }) }, Effect.none )

                _ ->
                    -- If we're not in AMRAP mode, start with settings open
                    ( { model | sessionMode = Just (AMRAP { settings | showSettings = True }) }, Effect.none )

        StartAMRAP ->
            ( model, Effect.getTime AMRAPStarted )

        AMRAPStarted time ->
            case model.sessionMode of
                Just (AMRAP settings) ->
                    ( { model
                        | sessionMode =
                            Just
                                (AMRAP
                                    { settings
                                        | showSettings = False
                                        , status = AMRAP.Running
                                        , startTime = time
                                        , currentTime = time
                                    }
                                )
                        , currentReps = 0
                      }
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        AMRAPTick newTime ->
            case model.sessionMode of
                Just (AMRAP settings) ->
                    let
                        ( remainingTime, _ ) =
                            AMRAP.remainingTime settings

                        isComplete : Bool
                        isComplete =
                            remainingTime <= 0

                        shouldStartWaiting : Bool
                        shouldStartWaiting =
                            isComplete && settings.status == AMRAP.Running

                        shouldRedirectNow : Bool
                        shouldRedirectNow =
                            case model.redirectTime of
                                Just startWait ->
                                    Time.posixToMillis newTime - Time.posixToMillis startWait >= 3000

                                Nothing ->
                                    False

                        newSettings : AMRAP.AMRAPSettings
                        newSettings =
                            { settings
                                | currentTime = newTime
                                , status =
                                    if isComplete then
                                        AMRAP.Finished

                                    else
                                        settings.status
                            }
                    in
                    ( { model
                        | sessionMode = Just (AMRAP newSettings)
                        , redirectTime =
                            if shouldStartWaiting then
                                Just newTime

                            else
                                model.redirectTime
                      }
                    , if shouldRedirectNow then
                        Effect.getTime GotWorkoutFinishedTime

                      else
                        Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        ToggleHelpModal ->
            ( { model | showHelpModal = True }
            , Effect.none
            )

        CloseHelpModal ->
            ( { model | showHelpModal = False }
            , Effect.none
            )

        ToggleSound ->
            ( { model | soundEnabled = not model.soundEnabled }
            , Effect.none
            )



-- Do nothing, just stop event propagation
-- SUBSCRIPTIONS


isSessionStarted : Model -> Bool
isSessionStarted model =
    case model.sessionMode of
        Just (EMOM setting) ->
            setting.status == EMOM.InProgress || setting.status == EMOM.Complete || setting.status == EMOM.Failed

        Just _ ->
            True

        _ ->
            False


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        debounce : Sub Msg
        debounce =
            if model.isDebouncing then
                Time.every 500 DebounceComplete

            else
                Sub.none

        workoutTick : Sub Msg
        workoutTick =
            case model.sessionMode of
                Just (EMOM settings) ->
                    if settings.status == EMOM.InProgress || settings.status == EMOM.Complete || settings.status == EMOM.Failed then
                        Time.every 100 EMOMTick

                    else
                        Sub.none

                Just (AMRAP settings) ->
                    if settings.status == AMRAP.Running || settings.status == AMRAP.Finished then
                        Time.every 100 AMRAPTick

                    else
                        Sub.none

                _ ->
                    Sub.none
    in
    Sub.batch [ debounce, workoutTick ]



-- VIEW
-- Create default EMOM settings
-- Remove the local defaultEMOMSettings function since it's now in the EMOM module
-- Remove: defaultEMOMSettings : Int -> EMOM.EMOMSettings
-- Remove the local defaultAMRAPSettings function since it's now in the AMRAP module
-- Remove: defaultAMRAPSettings : AMRAP.AMRAPSettings


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "BurpeeBootcamp"
    , body =
        if shared.initializing then
            [ text "Initializing..." ]

        else
            let
                updatedShowWelcomeModal : Bool
                updatedShowWelcomeModal =
                    List.isEmpty shared.workoutHistory

                isWorkoutFinished : Bool
                isWorkoutFinished =
                    case model.sessionMode of
                        Just (EMOM settings) ->
                            settings.status == EMOM.Complete || settings.status == EMOM.Failed

                        _ ->
                            False

                hasReachedGoal : Bool
                hasReachedGoal =
                    case model.sessionMode of
                        Just (Workout { totalGoal }) ->
                            model.currentReps >= totalGoal

                        Just (AMRAP settings) ->
                            settings.status == AMRAP.Finished

                        _ ->
                            model.currentReps
                                >= Session.Goal.calculateNextGoal
                                    { lastSessions = shared.workoutHistory, currentTime = shared.currentTime, timeZone = shared.timeZone }
                                    model.overwriteRepGoal
            in
            [ div [ class "flex flex-col items-center w-full h-screen relative" ]
                [ h1 [ class "mt-2 mb-2 font-semibold font-lora text-xl text-amber-800" ]
                    [ img
                        [ src "/logo/logo.png"
                        , class "h-32"
                        , alt "BurpeeBootcamp"
                        ]
                        []
                    ]
                , div [ class "relative" ]
                    [ if hasReachedGoal then
                        div [ class "absolute -top-2 -right-2 w-4 h-4 bg-green-500 rounded-full animate-ping z-10" ] []

                      else
                        text ""
                    , details
                        [ class "mb-4"
                        ]
                        [ summary [ class "text-lg mt-4 text-amber-800 font-semibold hover:text-amber-900 cursor-pointer select-none border border-amber-800/30 rounded px-3 py-1" ]
                            [ text "Show actions" ]
                        , div [ class "mt-2 space-y-2" ]
                            [ div [ class "flex gap-2" ]
                                -- Top row: Menu only (removed Reset Counter)
                                [ button
                                    [ class "flex-1 px-4 py-3 rounded-lg bg-amber-800/20 cursor-pointer select-none text-sm text-amber-900 active:bg-amber-800/30"
                                    , onClick ChangeToMenu
                                    ]
                                    [ text "Menu" ]
                                ]
                            , div [ class "flex gap-2" ]
                                -- Middle row: Sound toggle
                                [ button
                                    [ class "flex-1 px-4 py-3 rounded-lg bg-amber-800/20 cursor-pointer select-none text-sm text-amber-900 active:bg-amber-800/30"
                                    , onClick ToggleSound
                                    ]
                                    [ text
                                        (if model.soundEnabled then
                                            "🔊 Sound On"

                                         else
                                            "🔇 Sound Off"
                                        )
                                    ]
                                ]
                            , div [ class "flex gap-2" ]
                                -- Bottom row: Done button (full width)
                                [ button
                                    [ class "w-full px-4 py-3 rounded-lg text-sm"
                                    , classList
                                        [ ( "cursor-pointer bg-amber-800/20 text-amber-900 active:bg-amber-800/30", not isWorkoutFinished && not hasReachedGoal )
                                        , ( "opacity-50 cursor-not-allowed bg-gray-300/20 text-gray-600", isWorkoutFinished )
                                        , ( "bg-green-600 hover:bg-green-700 text-white font-medium", hasReachedGoal )
                                        ]
                                    , onClick GetWorkoutFinishedTime
                                    , Html.Attributes.disabled isWorkoutFinished
                                    ]
                                    [ text
                                        (if hasReachedGoal then
                                            "Save Session! 🎉"

                                         else
                                            "Done"
                                        )
                                    ]
                                ]
                            ]
                        ]
                    ]
                , div
                    (class "w-screen flex-1 flex flex-col items-center justify-start pt-8 bg-amber-100/30 cursor-pointer select-none touch-manipulation relative"
                        :: (if isSessionStarted model && not (hasModalOpen model) then
                                -- Add modal check
                                [ onClick IncrementReps ]

                            else
                                []
                           )
                    )
                    [ if model.isDebouncing then
                        text ""

                      else
                        div [ class "absolute inset-0 grid grid-cols-2 xl:grid-cols-4 gap-4 place-items-center place-content-center pointer-events-none overflow-hidden animate-fade-in" ]
                            (List.repeat 20
                                (div [ class "text-amber-800/5 text-4xl font-bold rotate-[-20deg] text-center" ]
                                    [ text "NOSE TAP AREA" ]
                                )
                            )
                    , case model.sessionMode of
                        Just (EMOM settings) ->
                            if settings.showSettings then
                                EMOM.viewConfig ConfigureEMOM
                                    StartEMOM
                                    (Session.Goal.calculateNextGoal
                                        { lastSessions = shared.workoutHistory, currentTime = shared.currentTime, timeZone = shared.timeZone }
                                        model.overwriteRepGoal
                                    )
                                    settings

                            else
                                EMOM.viewStatus shared
                                    { currentReps = model.currentReps
                                    , overwriteRepGoal = model.overwriteRepGoal
                                    , lastWarningTime = model.lastWarningTime
                                    }
                                    settings

                        Just (AMRAP settings) ->
                            if settings.showSettings then
                                AMRAP.viewConfig ConfigureAMRAP StartAMRAP shared settings

                            else
                                AMRAP.viewStatus { currentReps = model.currentReps } settings

                        _ ->
                            div
                                [ class "flex flex-col items-center gap-2 relative"
                                , classList
                                    [ ( "animate-scale-count", model.currentReps > 0 )
                                    ]
                                ]
                                [ div [ class "text-amber-800 opacity-80 text-sm mb-2" ]
                                    [ text (Maybe.withDefault Burpee.default shared.currentBurpee |> Burpee.getDisplayName) ]
                                , div [ class "text-6xl font-bold text-amber-900" ]
                                    [ text (String.fromInt model.currentReps) ]
                                , let
                                    goal : Int
                                    goal =
                                        case model.sessionMode of
                                            Just (Workout { totalGoal }) ->
                                                totalGoal

                                            _ ->
                                                Session.Goal.calculateNextGoal
                                                    { lastSessions = shared.workoutHistory, currentTime = shared.currentTime, timeZone = shared.timeZone }
                                                    model.overwriteRepGoal
                                  in
                                  div [ class "text-2xl opacity-80 text-amber-800" ]
                                    [ text <| " / " ++ String.fromInt goal ++ " reps" ]
                                , let
                                    requiredTouches : Int
                                    requiredTouches =
                                        shared.currentBurpee
                                            |> Maybe.withDefault Burpee.default
                                            |> Burpee.groundTouchesRequired
                                  in
                                  if requiredTouches > 1 then
                                    div [ class "text-lg text-amber-800 mt-2" ]
                                        [ text <| "Ground touches: " ++ String.fromInt model.groundTouchesForCurrentRep ++ "/" ++ String.fromInt requiredTouches ]

                                  else
                                    text ""
                                , div [ class "text-sm text-amber-800/70 mt-2 italic text-center" ]
                                    [ text "Take active rest by slow running in place"
                                    , br [] []
                                    , text "Just don't stop until you're done!"
                                    ]
                                ]
                    , div
                        [ class "text-lg text-amber-800 transition-opacity duration-300 mt-auto mb-8"
                        , classList
                            [ ( "opacity-0", model.currentReps > 0 )
                            , ( "opacity-100 animate-pulse", model.currentReps == 0 )
                            ]
                        ]
                        [ text "TAP TO COUNT" ]
                    ]
                , if model.initialShowWelcomeModal && updatedShowWelcomeModal then
                    div [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" ]
                        [ div [ class "bg-white p-6 rounded-lg shadow-xl max-w-sm mx-4" ]
                            [ h3 [ class "text-xl font-bold text-amber-900 mb-4" ]
                                [ text "Welcome to Burpee Bootcamp! 👋" ]
                            , div [ class "space-y-4 text-amber-800" ]
                                [ p []
                                    [ text "Here's how to count your burpees:" ]
                                , ul [ class "list-disc list-inside space-y-2" ]
                                    [ li [] [ text "Place your phone on the floor" ]
                                    , li [] [ text "Do your burpee" ]
                                    , li [] [ text "At the bottom position, tap the screen with your nose" ]
                                    ]
                                , p [ class "mt-4" ]
                                    [ text "Take active rest by slow running in place between reps. Just don't stop until you're done!" ]
                                , p [ class "mt-4" ]
                                    [ text "When you're finished, click "
                                    , span [ class "font-bold" ] [ text "Show actions" ]
                                    , text " at the top and save your workout!"
                                    ]
                                , p [ class "italic mt-4" ]
                                    [ text "Let's grow stronger together! 🌱 → 🌳" ]
                                ]
                            , button
                                [ class "mt-6 w-full px-4 py-2 bg-amber-800 text-white rounded-lg hover:bg-amber-900"
                                , onClick CloseWelcomeModal
                                ]
                                [ text "Let's go! 💪" ]
                            ]
                        ]

                  else
                    text ""
                , if model.sessionMode == Nothing then
                    viewSessionModeSelection shared model

                  else
                    text ""
                , if model.showHelpModal then
                    viewHelpModal

                  else
                    text ""
                ]
            ]
    }



-- Remove this function since AMRAP doesn't need separate stats
-- viewAMRAPStats : Model -> AMRAP.AMRAPSettings -> Html Msg
-- Pass message constructors first
-- Helper functions
-- Update the helper function to use AMRAP module


findBestAMRAPScore : List WorkoutResult.WorkoutResult -> Int -> Maybe Int
findBestAMRAPScore history selectedDuration =
    AMRAP.findBestScore history selectedDuration



-- Helper function to extract the increment logic


incrementReps : Shared.Model -> Model -> ( Model, Effect Msg )
incrementReps shared model =
    let
        requiredTouches : Int
        requiredTouches =
            shared.currentBurpee
                |> Maybe.withDefault Burpee.default
                |> Burpee.groundTouchesRequired

        newGroundTouches : Int
        newGroundTouches =
            model.groundTouchesForCurrentRep + 1

        shouldIncrementRep : Bool
        shouldIncrementRep =
            newGroundTouches >= requiredTouches

        newReps : Int
        newReps =
            if shouldIncrementRep then
                model.currentReps + 1

            else
                model.currentReps

        soundToPlay : Effect Msg
        soundToPlay =
            if shouldIncrementRep then
                let
                    hasReachedGoal : Bool
                    hasReachedGoal =
                        case model.sessionMode of
                            Just (Workout { totalGoal }) ->
                                newReps >= totalGoal

                            Just (AMRAP settings) ->
                                settings.status == AMRAP.Finished

                            _ ->
                                newReps
                                    >= Session.Goal.calculateNextGoal
                                        { lastSessions = shared.workoutHistory
                                        , currentTime = shared.currentTime
                                        , timeZone = shared.timeZone
                                        }
                                        model.overwriteRepGoal
                in
                if hasReachedGoal then
                    Effect.playSound Sound.WorkoutComplete

                else
                    Effect.playSound Sound.RepComplete

            else
                Effect.playSound Sound.GroundTouch
    in
    ( { model
        | currentReps = newReps
        , groundTouchesForCurrentRep =
            if shouldIncrementRep then
                0

            else
                newGroundTouches
        , isDebouncing = True
      }
    , soundToPlay
    )


viewSessionModeSelection : Shared.Model -> Model -> Html Msg
viewSessionModeSelection shared model =
    div [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" ]
        [ div [ class "bg-white p-6 rounded-lg shadow-xl max-w-sm mx-4" ]
            [ div [ class "flex justify-between items-center mb-4" ]
                [ h3 [ class "text-xl font-bold text-amber-900" ]
                    [ text "Choose Your Practice Style" ]
                , button
                    [ class """
                        w-8 h-8
                        flex items-center justify-center
                        rounded-full
                        bg-amber-100 hover:bg-amber-200
                        text-amber-800
                        transition-colors
                      """
                    , onClick ToggleHelpModal
                    ]
                    [ text "?" ]
                ]
            , div [ class "space-y-4" ]
                [ button
                    [ class "w-full px-4 py-3 bg-amber-800 text-white rounded-lg hover:bg-amber-900 transition-colors"
                    , onClick (SelectMode Free)
                    ]
                    [ text "Free Practice" ]
                , button
                    [ class "w-full px-4 py-3 bg-amber-800 text-white rounded-lg hover:bg-amber-900 transition-colors"
                    , onClick
                        (SelectMode
                            (EMOM
                                (EMOM.defaultSettings
                                    (Session.Goal.calculateNextGoal
                                        { lastSessions = shared.workoutHistory
                                        , currentTime = shared.currentTime
                                        , timeZone = shared.timeZone
                                        }
                                        model.overwriteRepGoal
                                    )
                                )
                            )
                        )
                    ]
                    [ text "EMOM" ]
                , button
                    [ class "w-full px-4 py-3 bg-amber-800 text-white rounded-lg hover:bg-amber-900 transition-colors"
                    , onClick (SelectMode (Workout { totalGoal = 0 }))
                    ]
                    [ text "Workout" ]
                , button
                    [ class "w-full px-4 py-3 bg-amber-800 text-white rounded-lg hover:bg-amber-900 transition-colors"
                    , onClick (SelectMode (AMRAP AMRAP.defaultSettings))
                    ]
                    [ text "AMRAP" ]
                ]
            ]
        ]


viewHelpModal : Html Msg
viewHelpModal =
    div
        [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        , onClick CloseHelpModal
        ]
        [ div
            [ class "bg-white p-6 rounded-lg shadow-xl max-w-sm mx-4"

            --, onClick (stopPropagation CloseHelpModal)
            ]
            [ div [ class "flex justify-between items-center mb-4" ]
                [ h3 [ class "text-xl font-bold text-amber-900" ]
                    [ text "Practice Styles Explained" ]
                , button
                    [ class """
                        w-8 h-8
                        flex items-center justify-center
                        rounded-full
                        bg-amber-100 hover:bg-amber-200
                        text-amber-800
                        transition-colors
                      """
                    , onClick CloseHelpModal
                    ]
                    [ text "×" ]
                ]
            , div [ class "space-y-4 text-amber-800" ]
                [ div [ class "space-y-2" ]
                    [ h4 [ class "font-bold" ] [ text "Free Practice" ]
                    , p [] [ text "Practice at your own pace with a target goal." ]
                    ]
                , div [ class "space-y-2" ]
                    [ h4 [ class "font-bold" ] [ text "EMOM" ]
                    , p [] [ text "Every Minute On the Minute: Complete a set number of reps within each minute." ]
                    ]
                , div [ class "space-y-2" ]
                    [ h4 [ class "font-bold" ] [ text "Workout" ]
                    , p [] [ text "Challenge yourself with a goal between 200% - 400% of your regular goal." ]
                    ]
                , div [ class "space-y-2" ]
                    [ h4 [ class "font-bold" ] [ text "AMRAP" ]
                    , p [] [ text "As Many Reps As Possible: Complete as many reps as you can within a time limit." ]
                    ]
                ]
            ]
        ]



-- Add this new helper function
-- Play every 2 seconds
-- Add this helper function


hasModalOpen : Model -> Bool
hasModalOpen model =
    case model.sessionMode of
        Just (EMOM settings) ->
            settings.showSettings

        Just (AMRAP settings) ->
            settings.showSettings

        _ ->
            model.initialShowWelcomeModal || model.showHelpModal
