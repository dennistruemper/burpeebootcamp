module Pages.Counter exposing
    ( AMRAPSettings
    , AMRAPStatus
    , EMOMSettings
    , EMOMStatus(..)
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
import Html.Attributes exposing (alt, class, classList, src, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Session.Goal
import Shared
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
    | EMOM EMOMSettings
    | Workout { totalGoal : Int }
    | AMRAP AMRAPSettings


type EMOMStatus
    = WaitingToStart
    | InProgress
    | Complete
    | Failed


type AMRAPStatus
    = NotStarted
    | Running
    | Finished


type alias EMOMSettings =
    { startTime : Time.Posix
    , repsPerMinute : Int
    , totalRounds : Int
    , currentRound : Int
    , status : EMOMStatus
    , showSettings : Bool
    , currentTickTime : Time.Posix
    }


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

        ResetCounter ->
            ( { model
                | currentReps = 0
                , groundTouchesForCurrentRep = 0
                , redirectTime = Nothing
              }
            , Effect.none
            )

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
                        | sessionMode = Just (EMOM (defaultEMOMSettings repGoal))
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
                    if settings.status == WaitingToStart then
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

                            isComplete : Bool
                            isComplete =
                                settings.currentRound > settings.totalRounds

                            isFailed : Bool
                            isFailed =
                                isNewMinute
                                    && model.currentReps
                                    < min
                                        (Session.Goal.calculateNextGoal
                                            { lastSessions = shared.workoutHistory, currentTime = shared.currentTime, timeZone = shared.timeZone }
                                            model.overwriteRepGoal
                                        )
                                        (settings.repsPerMinute * settings.currentRound)

                            shouldStartWaiting : Bool
                            shouldStartWaiting =
                                (isComplete || isFailed) && settings.status == InProgress

                            shouldRedirectNow : Bool
                            shouldRedirectNow =
                                case model.redirectTime of
                                    Just startWait ->
                                        Time.posixToMillis newTime - Time.posixToMillis startWait >= 10000

                                    Nothing ->
                                        False

                            newStatus : EMOMStatus
                            newStatus =
                                if shouldStartWaiting then
                                    if isComplete then
                                        Complete

                                    else
                                        Failed

                                else
                                    settings.status

                            newSettings : EMOMSettings
                            newSettings =
                                if isNewMinute && not isComplete then
                                    { settings
                                        | currentRound = settings.currentRound + 1
                                        , status = newStatus
                                        , currentTickTime = newTime
                                    }

                                else
                                    { settings | currentTickTime = newTime, status = newStatus }
                        in
                        ( { model
                            | sessionMode = Just (EMOM newSettings)
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

        StartEMOM ->
            ( model, Effect.getTime EMOMStarted )

        EMOMStarted time ->
            case model.sessionMode of
                Just (EMOM settings) ->
                    ( { model
                        | sessionMode =
                            Just (EMOM { settings | showSettings = False, status = InProgress, startTime = time })
                        , currentReps = 0
                      }
                    , Effect.none
                    )

                Nothing ->
                    let
                        emomSetting : EMOMSettings
                        emomSetting =
                            defaultEMOMSettings
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
                            remainingAMRAPTime { settings | currentTime = newTime }

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



-- SUBSCRIPTIONS


isSessionStarted : Model -> Bool
isSessionStarted model =
    case model.sessionMode of
        Just (EMOM setting) ->
            setting.status == InProgress || setting.status == Complete || setting.status == Failed

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
                    if settings.status == InProgress || settings.status == Complete || settings.status == Failed then
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


defaultEMOMSettings : Int -> EMOMSettings
defaultEMOMSettings repGoal =
    { startTime = Time.millisToPosix 0
    , repsPerMinute = 5
    , totalRounds = ceiling (toFloat repGoal / 5.0) -- Default to 10 reps per round
    , currentRound = 1
    , status = WaitingToStart
    , showSettings = True
    , currentTickTime = Time.millisToPosix 0
    }


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
                            settings.status == Complete || settings.status == Failed

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
                        , div [ class "flex justify-between gap-4 mt-2" ]
                            [ div [ class "flex gap-4" ]
                                [ button
                                    [ class "px-6 py-3 rounded-lg bg-amber-800/20 cursor-pointer select-none text-sm text-amber-900 active:bg-amber-800/30"
                                    , onClick ResetCounter
                                    ]
                                    [ text "Reset Counter" ]
                                , button
                                    [ class "px-6 py-3 rounded-lg bg-amber-800/20 cursor-pointer select-none text-sm text-amber-900 active:bg-amber-800/30"
                                    , onClick ChangeToMenu
                                    ]
                                    [ text "Menu" ]
                                ]
                            , button
                                [ class "px-6 py-3 rounded-lg text-sm"
                                , classList
                                    [ ( "cursor-pointer bg-green-700/20 text-green-900 active:bg-green-700/30", not isWorkoutFinished && not hasReachedGoal )
                                    , ( "opacity-50 cursor-not-allowed", isWorkoutFinished )
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
                , div
                    (class "w-screen flex-1 flex flex-col items-center justify-center bg-amber-100/30 cursor-pointer select-none touch-manipulation relative"
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
                                viewEMOMConfig
                                    (Session.Goal.calculateNextGoal
                                        { lastSessions = shared.workoutHistory, currentTime = shared.currentTime, timeZone = shared.timeZone }
                                        model.overwriteRepGoal
                                    )
                                    settings

                            else
                                viewEMOMStatus shared model settings

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
                        [ class "text-lg text-amber-800 transition-opacity duration-300"
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


viewEMOMConfig : Int -> EMOMSettings -> Html Msg
viewEMOMConfig repGoal settings =
    div [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" ]
        [ div [ class "bg-white p-6 rounded-lg shadow-xl max-w-sm mx-4" ]
            [ h3 [ class "text-xl font-bold text-amber-900 mb-4" ]
                [ text "Configure EMOM Workout" ]
            , div [ class "space-y-4" ]
                [ div [ class "flex flex-col gap-2" ]
                    [ div [ class "flex justify-between items-center" ]
                        [ label [ class "text-amber-900" ] [ text "Reps per minute" ]
                        , span [ class "text-amber-900 font-bold" ]
                            [ text (String.fromInt settings.repsPerMinute) ]
                        ]
                    , input
                        [ type_ "range"
                        , Html.Attributes.min "1"
                        , Html.Attributes.max "10"
                        , Html.Attributes.step "1"
                        , value (String.fromInt settings.repsPerMinute)
                        , onInput
                            (\str ->
                                let
                                    newRepsPerMinute : Int
                                    newRepsPerMinute =
                                        Maybe.withDefault settings.repsPerMinute (String.toInt str)

                                    newTotalRounds : Int
                                    newTotalRounds =
                                        ceiling (toFloat repGoal / toFloat newRepsPerMinute)
                                in
                                ConfigureEMOM
                                    { settings
                                        | repsPerMinute = newRepsPerMinute
                                        , totalRounds = newTotalRounds
                                    }
                            )
                        , class "w-full h-2 bg-amber-200 rounded-lg appearance-none cursor-pointer accent-amber-600"
                        ]
                        []
                    ]
                , div [ class "text-amber-800 mt-2" ]
                    [ text <| "Total rounds: " ++ String.fromInt settings.totalRounds ]
                , div [ class "text-amber-800/70 text-sm italic" ]
                    [ text <| "To reach your goal of " ++ String.fromInt repGoal ++ " reps" ]
                , button
                    [ class "w-full px-4 py-3 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors mt-4"
                    , onClick StartEMOM
                    ]
                    [ text "Start Workout" ]
                ]
            ]
        ]


viewEMOMStatus : Shared.Model -> Model -> EMOMSettings -> Html Msg
viewEMOMStatus shared model settings =
    let
        timeRemaining : Int
        timeRemaining =
            remainingTimeInCurrentMinute settings.startTime settings.currentTickTime

        isLastTenSeconds : Bool
        isLastTenSeconds =
            timeRemaining <= 10

        repGoal : Int
        repGoal =
            Session.Goal.calculateNextGoal
                { lastSessions = shared.workoutHistory
                , currentTime = shared.currentTime
                , timeZone = shared.timeZone
                }
                model.overwriteRepGoal

        roundDisplay : String
        roundDisplay =
            case settings.status of
                Complete ->
                    "Practice Complete! 🎉"

                Failed ->
                    "Practice Failed! 😢"

                _ ->
                    "Round " ++ String.fromInt settings.currentRound ++ " / " ++ String.fromInt settings.totalRounds

        currentRoundGoal : Int
        currentRoundGoal =
            min (settings.repsPerMinute * settings.currentRound) repGoal
    in
    div [ class "absolute top-4 right-4 bg-amber-100 p-4 rounded-lg shadow-md min-w-[200px]" ]
        [ div [ class "text-2xl font-bold text-amber-900 flex justify-between items-center" ]
            [ text roundDisplay
            ]
        , div [ class "text-xl text-amber-800 mt-2" ]
            [ text <| String.fromInt model.currentReps ++ " / " ++ String.fromInt currentRoundGoal ++ " reps" ]
        , div [ class "w-full bg-amber-200 rounded-full h-2 mt-2" ]
            [ div
                [ class "bg-amber-600 h-2 rounded-full transition-all duration-200"
                , style "width" (String.fromFloat (remainingTimePercent timeRemaining) ++ "%")
                , classList [ ( "bg-red-600", isLastTenSeconds ) ]
                ]
                []
            ]
        , viewEMOMStats model settings currentRoundGoal
        ]


viewEMOMStats : Model -> EMOMSettings -> Int -> Html Msg
viewEMOMStats model settings currentRoundGoal =
    div [ class "mt-4 text-sm text-amber-800" ]
        [ div [ class "flex justify-between" ]
            [ text "Average reps/round:"
            , text (String.fromFloat (toFloat (round (toFloat model.currentReps / toFloat settings.currentRound * 10)) / 10))
            ]
        , div [ class "flex justify-between" ]
            [ text "Completion rate:"
            , text (String.fromInt (round (toFloat model.currentReps / toFloat currentRoundGoal * 100)) ++ "%")
            ]
        ]


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
    let
        elapsed : Int
        elapsed =
            modBy 60000 (Time.posixToMillis currentTime - Time.posixToMillis startTime)
    in
    (60000 - elapsed) // 1000


remainingTimePercent : Int -> Float
remainingTimePercent seconds =
    toFloat seconds / 60.0 * 100


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
    in
    ( { model
        | currentReps =
            if shouldIncrementRep then
                model.currentReps + 1

            else
                model.currentReps
        , groundTouchesForCurrentRep =
            if shouldIncrementRep then
                0

            else
                newGroundTouches
        , isDebouncing = True
      }
    , Effect.none
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
                                (defaultEMOMSettings
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
