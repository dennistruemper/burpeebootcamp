module Pages.Counter exposing
    ( AMRAPSettings
    , AMRAPStatus(..)
    , Model
    , Msg(..)
    , SessionMode(..)
    , page
    )

import Burpee
import Dict
import Effect exposing (Effect)
import Env
import Html exposing (Html, br, button, details, div, h1, h3, h4, img, input, label, li, p, span, summary, text, ul)
import Html.Attributes exposing (alt, checked, class, classList, src, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page)
import Pages.Counter.EMOM as EMOM
import Route exposing (Route)
import Route.Path
import Session.Goal
import Shared
import Sound exposing (Sound(..), toString)
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
    | AMRAP AMRAPSettings


type AMRAPStatus
    = NotStarted
    | Running
    | Finished


type EMOMMode
    = FixedRounds -- Original mode with set number of rounds
    | EndlessMode -- New mode that continues until failure


type alias AMRAPSettings =
    { duration : Int -- in minutes
    , startTime : Time.Posix
    , currentTime : Time.Posix
    , status : AMRAPStatus
    , showSettings : Bool
    , previousBest : Maybe Int
    }


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
    | ConfigureAMRAP AMRAPSettings
    | StartAMRAP
    | AMRAPStarted Time.Posix
    | AMRAPTick Time.Posix
    | ToggleHelpModal
    | CloseHelpModal
    | ToggleSound
    | PlayTimerWarning


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
                        if settings.status == Finished then
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
                        previousBest : Maybe Int
                        previousBest =
                            findBestAMRAPScore shared.workoutHistory defaultAMRAPSettings.duration
                    in
                    ( { model
                        | sessionMode =
                            Just
                                (AMRAP
                                    { defaultAMRAPSettings
                                        | previousBest = previousBest
                                    }
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
            ( { model | sessionMode = Just (AMRAP settings) }, Effect.none )

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
                                        , status = Running
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
                            remainingAMRAPTime settings

                        isComplete : Bool
                        isComplete =
                            remainingTime <= 0

                        shouldStartWaiting : Bool
                        shouldStartWaiting =
                            isComplete && settings.status == Running

                        shouldRedirectNow : Bool
                        shouldRedirectNow =
                            case model.redirectTime of
                                Just startWait ->
                                    Time.posixToMillis newTime - Time.posixToMillis startWait >= 3000

                                Nothing ->
                                    False

                        newSettings : AMRAPSettings
                        newSettings =
                            { settings
                                | currentTime = newTime
                                , status =
                                    if isComplete then
                                        Finished

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

        PlayTimerWarning ->
            ( { model | lastWarningTime = Just shared.currentTime }
            , if model.soundEnabled then
                Effect.playSound Sound.TimerWarning

              else
                Effect.none
            )



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
                    if settings.status == Running || settings.status == Finished then
                        Time.every 100 AMRAPTick

                    else
                        Sub.none

                _ ->
                    Sub.none
    in
    Sub.batch [ debounce, workoutTick ]



-- VIEW
-- Create default EMOM settings


defaultEMOMSettings : Int -> EMOM.EMOMSettings
defaultEMOMSettings repGoal =
    EMOM.defaultSettings repGoal


defaultAMRAPSettings : AMRAPSettings
defaultAMRAPSettings =
    { duration = 20
    , startTime = Time.millisToPosix 0
    , currentTime = Time.millisToPosix 0
    , status = NotStarted
    , showSettings = True
    , previousBest = Nothing
    }


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
                            settings.status == Finished

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
                        :: (if isSessionStarted model then
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
                                viewAMRAPConfig shared settings

                            else
                                let
                                    ( timeRemaining, progress ) =
                                        remainingAMRAPTime settings
                                in
                                div [ class "flex flex-col items-center gap-4" ]
                                    [ if settings.status == Finished then
                                        div [ class "text-4xl font-bold text-amber-900 mb-2" ]
                                            [ text "Time's up!" ]

                                      else
                                        let
                                            minutes : Int
                                            minutes =
                                                timeRemaining // 60

                                            seconds : Int
                                            seconds =
                                                modBy 60 timeRemaining

                                            timeDisplay : String
                                            timeDisplay =
                                                String.fromInt minutes
                                                    ++ ":"
                                                    ++ (if seconds < 10 then
                                                            "0"

                                                        else
                                                            ""
                                                       )
                                                    ++ String.fromInt seconds
                                        in
                                        div [ class "text-4xl font-bold text-amber-900 mb-2" ]
                                            [ text timeDisplay ]
                                    , div [ class "text-6xl font-bold text-amber-900" ]
                                        [ text (String.fromInt model.currentReps) ]
                                    , div [ class "text-2xl text-amber-800" ]
                                        [ text "reps" ]
                                    , div [ class "w-64 bg-amber-200 rounded-full h-2 mt-2" ]
                                        [ div
                                            [ class "bg-amber-600 h-2 rounded-full transition-all duration-200"
                                            , style "width" (String.fromInt progress ++ "%")
                                            ]
                                            []
                                        ]
                                    , case settings.previousBest of
                                        Just best ->
                                            div [ class "text-xl text-amber-800 mt-2" ]
                                                [ text <| "Previous best: " ++ String.fromInt best ]

                                        Nothing ->
                                            text ""
                                    , div [ class "text-sm text-amber-800/70 mt-4 italic text-center" ]
                                        [ text "Keep pushing! Don't stop until time runs out!" ]
                                    ]

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


viewEMOMConfig : Int -> EMOM.EMOMSettings -> Html Msg
viewEMOMConfig repGoal settings =
    EMOM.viewConfig ConfigureEMOM StartEMOM repGoal settings


viewEMOMStatus : Shared.Model -> Model -> EMOM.EMOMSettings -> Html Msg
viewEMOMStatus shared model settings =
    EMOM.viewStatus shared
        { currentReps = model.currentReps
        , overwriteRepGoal = model.overwriteRepGoal
        , lastWarningTime = model.lastWarningTime
        }
        settings


viewEMOMStats : Model -> EMOM.EMOMSettings -> Html Msg
viewEMOMStats model settings =
    EMOM.viewStats { currentReps = model.currentReps, lastWarningTime = Nothing } settings


viewAMRAPConfig : Shared.Model -> AMRAPSettings -> Html Msg
viewAMRAPConfig shared settings =
    let
        hasAnyAMRAPHistory : Bool
        hasAnyAMRAPHistory =
            shared.workoutHistory
                |> List.any
                    (\workout ->
                        case workout.sessionType of
                            Just (WorkoutResult.StoredAMRAP _) ->
                                True

                            _ ->
                                False
                    )
    in
    div [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" ]
        [ div [ class "bg-white p-6 rounded-lg shadow-xl max-w-sm mx-4" ]
            [ h3 [ class "text-xl font-bold text-amber-900 mb-4" ]
                [ text "Configure AMRAP Session" ]
            , if not hasAnyAMRAPHistory then
                div
                    [ class """
                        mb-4 p-3 rounded-lg
                        bg-amber-50 border border-amber-200
                        text-amber-800 text-sm
                      """
                    ]
                    [ div [ class "font-medium mb-1" ]
                        [ text "⚠️ First AMRAP Session" ]
                    , p []
                        [ text """
                            Remember: Quality over quantity! Maintain proper form throughout
                            the session to prevent injury. It's better to do fewer reps
                            with good form than many with poor form.
                          """
                        ]
                    ]

              else
                text ""
            , div [ class "space-y-4" ]
                [ div [ class "flex flex-col gap-2" ]
                    [ div [ class "flex justify-between items-center" ]
                        [ label [ class "text-amber-900" ] [ text "Duration (minutes)" ]
                        , span [ class "text-amber-900 font-bold" ]
                            [ text (String.fromInt settings.duration) ]
                        ]
                    , input
                        [ type_ "range"
                        , Html.Attributes.min
                            "1"
                        , Html.Attributes.max
                            (if Env.mode == Env.Production then
                                "60"

                             else
                                "20"
                            )
                        , Html.Attributes.step
                            "1"
                        , value (String.fromInt settings.duration)
                        , onInput
                            (\str ->
                                let
                                    newDuration : Int
                                    newDuration =
                                        Maybe.withDefault settings.duration (String.toInt str)

                                    previousBest : Maybe Int
                                    previousBest =
                                        findBestAMRAPScore shared.workoutHistory newDuration
                                in
                                ConfigureAMRAP
                                    { settings
                                        | duration = newDuration
                                        , previousBest = previousBest
                                    }
                            )
                        , class "w-full h-2 bg-amber-200 rounded-lg appearance-none cursor-pointer accent-amber-600"
                        ]
                        []
                    ]
                , case settings.previousBest of
                    Just best ->
                        div [ class "text-amber-800 mt-2 p-3 bg-amber-50 rounded-lg" ]
                            [ div [ class "font-medium" ] [ text "Previous Best" ]
                            , div [ class "text-2xl font-bold" ]
                                [ text (String.fromInt best)
                                , span [ class "text-base font-normal ml-2" ] [ text "reps" ]
                                ]
                            , div [ class "text-sm text-amber-600" ]
                                [ text ("in " ++ String.fromInt settings.duration ++ " minutes") ]
                            ]

                    Nothing ->
                        div [ class "text-amber-800/70 text-sm italic text-center" ]
                            [ text "No previous attempts for this duration" ]
                , button
                    [ class "w-full px-4 py-3 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors mt-4"
                    , onClick StartAMRAP
                    ]
                    [ text "Start AMRAP" ]
                ]
            ]
        ]



-- Helper functions


remainingTimeInCurrentMinute : Time.Posix -> Time.Posix -> Int
remainingTimeInCurrentMinute startTime currentTime =
    EMOM.remainingTimeInCurrentMinute startTime currentTime


remainingTimePercent : Int -> Float
remainingTimePercent seconds =
    EMOM.remainingTimePercent seconds


remainingAMRAPTime : AMRAPSettings -> ( Int, Int )
remainingAMRAPTime settings =
    let
        elapsed : Int
        elapsed =
            (Time.posixToMillis settings.currentTime - Time.posixToMillis settings.startTime) // 1000

        totalSeconds : Int
        totalSeconds =
            settings.duration * 60
    in
    ( max 0 (totalSeconds - elapsed)
    , round (toFloat elapsed / toFloat totalSeconds * 100)
    )


findBestAMRAPScore : List WorkoutResult.WorkoutResult -> Int -> Maybe Int
findBestAMRAPScore history selectedDuration =
    history
        |> List.filterMap
            (\workout ->
                case workout.sessionType of
                    Just (WorkoutResult.StoredAMRAP { duration }) ->
                        if duration == selectedDuration then
                            Just workout.reps

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.maximum



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

        -- Check if goal is reached with the new rep count
        hasReachedGoal : Bool
        hasReachedGoal =
            case model.sessionMode of
                Just (Workout { totalGoal }) ->
                    newReps >= totalGoal

                Just (AMRAP settings) ->
                    settings.status == Finished

                _ ->
                    newReps
                        >= Session.Goal.calculateNextGoal
                            { lastSessions = shared.workoutHistory
                            , currentTime = shared.currentTime
                            , timeZone = shared.timeZone
                            }
                            model.overwriteRepGoal

        -- Determine which sound to play (only if sound is enabled)
        soundToPlay : Effect Msg
        soundToPlay =
            if model.soundEnabled then
                if shouldIncrementRep then
                    if hasReachedGoal then
                        Effect.playSound Sound.WorkoutComplete
                        -- Goal reached!

                    else
                        Effect.playSound Sound.RepComplete
                    -- Regular rep complete

                else
                    Effect.playSound Sound.GroundTouch
                -- Ground touch

            else
                Effect.none

        -- No sound if disabled
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
                    , onClick (SelectMode (AMRAP defaultAMRAPSettings))
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


isBehindPace : Model -> EMOM.EMOMSettings -> Bool
isBehindPace model settings =
    EMOM.isBehindPace { currentReps = model.currentReps, lastWarningTime = model.lastWarningTime } settings


shouldPlayTimerWarning : Model -> EMOM.EMOMSettings -> Time.Posix -> Bool
shouldPlayTimerWarning model settings currentTime =
    EMOM.shouldPlayTimerWarning { currentReps = model.currentReps, lastWarningTime = model.lastWarningTime } settings currentTime



-- Play every 2 seconds
