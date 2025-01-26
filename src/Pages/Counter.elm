module Pages.Counter exposing
    ( EMOMSettings
    , EMOMStatus(..)
    , Model
    , Msg(..)
    , SessionMode(..)
    , page
    )

import Burpee
import Dict
import Effect exposing (Effect)
import Html exposing (Html, br, button, details, div, h1, h3, img, input, label, li, p, span, summary, text, ul)
import Html.Attributes exposing (alt, class, classList, src, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page)
import Random
import Route exposing (Route)
import Route.Path
import Shared
import Time
import View exposing (View)
import WorkoutResult exposing (WorkoutResult)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init shared route
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


calculateNextGoal : Shared.Model -> Model -> Int
calculateNextGoal shared model =
    case model.overwriteRepGoal of
        Just repGoal ->
            Basics.max 10 repGoal

        Nothing ->
            let
                lastWorkout : Maybe WorkoutResult
                lastWorkout =
                    shared.workoutHistory |> List.sortBy (\workout -> workout.timestamp |> Time.posixToMillis) |> List.reverse |> List.head

                daysSinceLastWorkout : Int
                daysSinceLastWorkout =
                    case lastWorkout of
                        Just workout ->
                            Time.posixToMillis shared.currentTime
                                - Time.posixToMillis workout.timestamp
                                |> (\ms ->
                                        toFloat ms / (1000 * 60 * 60 * 24)
                                   )
                                |> floor

                        Nothing ->
                            999

                adjustedGoal : Int
                adjustedGoal =
                    if daysSinceLastWorkout <= 1 then
                        -- Yesterday's workout
                        case lastWorkout of
                            Just lw ->
                                let
                                    wasGoalReached : Bool
                                    wasGoalReached =
                                        case lastWorkout of
                                            Just workout ->
                                                Maybe.map2 (\goal reps -> reps >= goal) workout.repGoal (Just workout.reps)
                                                    |> Maybe.withDefault False

                                            Nothing ->
                                                False
                                in
                                if wasGoalReached then
                                    (lw.repGoal |> Maybe.withDefault 10) + 1

                                else
                                    lw.repGoal |> Maybe.withDefault 10

                            Nothing ->
                                10

                    else
                        -- Missed days
                        case lastWorkout of
                            Just lw ->
                                (lw.repGoal |> Maybe.withDefault 10) - (2 * (daysSinceLastWorkout - 1))

                            Nothing ->
                                10
            in
            Basics.max 10 adjustedGoal


type SessionMode
    = Free
    | EMOM EMOMSettings
    | Workout { totalGoal : Int }


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


type alias Model =
    { currentReps : Int
    , overwriteRepGoal : Maybe Int
    , initialShowWelcomeModal : Bool
    , groundTouchesForCurrentRep : Int
    , sessionMode : Maybe SessionMode
    , isMysteryMode : Bool
    , redirectTime : Maybe Time.Posix
    , isDebouncing : Bool
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
            ( { model | redirectTime = Nothing }
            , Effect.batch
                [ Effect.storeWorkoutResult
                    { reps = model.currentReps
                    , burpee = Maybe.withDefault Burpee.default shared.currentBurpee
                    , timestamp = time
                    , repGoal = Just (calculateNextGoal shared model)
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
                    let
                        dailyGoal : Int
                        dailyGoal =
                            calculateNextGoal shared model
                    in
                    ( model
                    , Effect.getRandom
                        (Random.int (min 200 (dailyGoal * 2)) (min 200 (dailyGoal * 4)))
                        GotWorkoutGoal
                    )

                EMOM _ ->
                    let
                        repGoal : Int
                        repGoal =
                            calculateNextGoal shared model
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
                                isNewMinute && model.currentReps < min (calculateNextGoal shared model) (settings.repsPerMinute * settings.currentRound)

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
                            defaultEMOMSettings (calculateNextGoal shared model)
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
                Time.every 1000 DebounceComplete

            else
                Sub.none

        emomTick : Sub Msg
        emomTick =
            if isSessionStarted model then
                Time.every 100 EMOMTick

            else
                Sub.none
    in
    Sub.batch [ debounce, emomTick ]



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

                        _ ->
                            model.currentReps >= calculateNextGoal shared model
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
                                viewEMOMConfig (calculateNextGoal shared model) settings

                            else
                                viewEMOMStatus shared model settings

                        _ ->
                            text ""
                    , div
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
                                        calculateNextGoal shared model
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
                    div [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" ]
                        [ div [ class "bg-white p-6 rounded-lg shadow-xl max-w-sm mx-4" ]
                            [ h3 [ class "text-xl font-bold text-amber-900 mb-4" ]
                                [ text "Choose Your Practice Style" ]
                            , div [ class "space-y-4" ]
                                [ button
                                    [ class "w-full px-4 py-3 bg-amber-800 text-white rounded-lg hover:bg-amber-900 transition-colors mb-3"
                                    , onClick (SelectMode Free)
                                    ]
                                    [ text "Freestyle" ]
                                , button
                                    [ class "w-full px-4 py-3 bg-amber-800 text-white rounded-lg hover:bg-amber-900 transition-colors mb-3"
                                    , onClick (SelectMode (EMOM (defaultEMOMSettings (calculateNextGoal shared model))))
                                    ]
                                    [ text "EMOM (Every Minute On the Minute)" ]
                                , button
                                    [ class "w-full px-4 py-3 bg-amber-800 text-white rounded-lg hover:bg-amber-900 transition-colors"
                                    , onClick (SelectMode (Workout { totalGoal = 0 }))
                                    ]
                                    [ text "Workout ( 200% - 400% of goal)" ]
                                ]
                            ]
                        ]

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
            calculateNextGoal shared model

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
