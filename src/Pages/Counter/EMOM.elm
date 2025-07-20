module Pages.Counter.EMOM exposing
    ( EMOMMode(..)
    , EMOMSettings
    , EMOMStatus(..)
    , defaultSettings
    , isBehindPace
    , remainingTimeInCurrentMinute
    , remainingTimePercent
    , shouldPlayTimerWarning
    , viewConfig
    , viewStats
    , viewStatus
    )

import Html exposing (Html, button, div, h3, input, label, span, text)
import Html.Attributes exposing (checked, class, classList, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Session.Goal
import Shared
import Sound exposing (Sound(..))
import Time
import WorkoutResult



-- Add this type alias for the model fields we need


type alias ModelFields =
    { currentReps : Int
    , overwriteRepGoal : Maybe Int
    , lastWarningTime : Maybe Time.Posix
    }



-- TYPES


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



-- HELPER FUNCTIONS


defaultSettings : Int -> EMOMSettings
defaultSettings repGoal =
    { startTime = Time.millisToPosix 0
    , repsPerMinute = 5
    , totalRounds = ceiling (toFloat repGoal / 5.0)
    , currentRound = 1
    , status = WaitingToStart
    , showSettings = True
    , currentTickTime = Time.millisToPosix 0
    , mode = FixedRounds
    }


isBehindPace : { currentReps : Int, lastWarningTime : Maybe Time.Posix } -> EMOMSettings -> Bool
isBehindPace model settings =
    let
        repsInCurrentRound : Int
        repsInCurrentRound =
            model.currentReps - (settings.currentRound - 1) * settings.repsPerMinute
    in
    if repsInCurrentRound == 0 then
        False

    else
        let
            elapsedInRound : Int
            elapsedInRound =
                modBy 60000 (Time.posixToMillis settings.currentTickTime - Time.posixToMillis settings.startTime)

            targetTimePerRep : Float
            targetTimePerRep =
                60000 / toFloat settings.repsPerMinute
        in
        toFloat elapsedInRound >= (toFloat repsInCurrentRound * targetTimePerRep)


shouldPlayTimerWarning : { currentReps : Int, lastWarningTime : Maybe Time.Posix } -> EMOMSettings -> Time.Posix -> Bool
shouldPlayTimerWarning model settings currentTime =
    isBehindPace model settings
        && model.currentReps
        > 0
        && (model.lastWarningTime
                == Nothing
                || Time.posixToMillis currentTime
                - Time.posixToMillis (Maybe.withDefault (Time.millisToPosix 0) model.lastWarningTime)
                > 2000
           )


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



-- VIEW FUNCTIONS


viewConfig : (EMOMSettings -> msg) -> msg -> Int -> EMOMSettings -> Html msg
viewConfig configureEMOMMsg startEMOMMsg repGoal settings =
    div [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" ]
        [ div [ class "bg-white rounded-lg shadow-xl w-full max-w-sm" ]
            [ h3 [ class "text-xl font-bold text-amber-900 p-6 border-b border-amber-100" ]
                [ text "Configure EMOM Workout" ]
            , div [ class "p-6 space-y-6" ]
                [ div [ class "flex flex-col gap-3" ]
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
                                        if settings.mode == FixedRounds then
                                            ceiling (toFloat repGoal / toFloat newRepsPerMinute)

                                        else
                                            settings.totalRounds
                                in
                                configureEMOMMsg
                                    { settings
                                        | repsPerMinute = newRepsPerMinute
                                        , totalRounds = newTotalRounds
                                    }
                            )
                        , class "w-full h-2 bg-amber-200 rounded-lg appearance-none cursor-pointer accent-amber-600"
                        ]
                        []
                    ]
                , div [ class "flex items-center gap-2 py-2" ]
                    [ input
                        [ type_ "checkbox"
                        , checked (settings.mode == EndlessMode)
                        , onClick
                            (configureEMOMMsg
                                { settings
                                    | mode =
                                        if settings.mode == EndlessMode then
                                            FixedRounds

                                        else
                                            EndlessMode
                                }
                            )
                        , class "w-4 h-4 text-amber-600 rounded border-amber-300 focus:ring-amber-500"
                        ]
                        []
                    , label [ class "text-amber-900" ]
                        [ text "Workout" ]
                    ]
                , if settings.mode == FixedRounds then
                    div [ class "text-amber-800" ]
                        [ text <| "Total rounds: " ++ String.fromInt settings.totalRounds
                        , div [ class "text-amber-800/70 text-sm italic mt-1" ]
                            [ text <| "To reach your goal of " ++ String.fromInt repGoal ++ " reps" ]
                        ]

                  else
                    div [ class "text-amber-700/70 text-sm italic" ]
                        [ text "Complete the required reps each minute. Keep going until you can't!" ]
                , button
                    [ class "w-full px-4 py-3 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors mt-4"
                    , onClick startEMOMMsg
                    ]
                    [ text
                        ("Start "
                            ++ (if settings.mode == EndlessMode then
                                    "Workout"

                                else
                                    "Session"
                               )
                        )
                    ]
                ]
            ]
        ]


viewStatus : Shared.Model -> ModelFields -> EMOMSettings -> Html msg
viewStatus shared model settings =
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
                    let
                        isGoalReached : Bool
                        isGoalReached =
                            model.currentReps >= repGoal
                    in
                    if isGoalReached then
                        "Goal Reached! 🎉"

                    else
                        "Round " ++ String.fromInt settings.currentRound ++ " / " ++ String.fromInt settings.currentRound

        repsInCurrentRound : Int
        repsInCurrentRound =
            model.currentReps - (settings.currentRound - 1) * settings.repsPerMinute
    in
    div [ class "flex flex-col items-center gap-6" ]
        [ div [ class "text-2xl font-bold text-amber-900" ]
            [ text roundDisplay ]
        , div [ class "flex flex-col items-center" ]
            [ div [ class "flex items-baseline font-mono" ]
                [ div [ class "text-xl text-amber-800 mr-2" ]
                    [ text "⏱️" ]
                , div [ class "text-4xl font-bold text-amber-900" ]
                    [ text (String.fromInt timeRemaining) ]
                , div [ class "text-xl text-amber-800 ml-1" ]
                    [ text "sec" ]
                ]
            , div [ class "w-64 bg-amber-200 rounded-full h-2 mt-2" ]
                [ div
                    [ class "h-full rounded-full transition-all duration-200"
                    , classList [ ( "bg-red-600", isLastTenSeconds ), ( "bg-amber-600", not isLastTenSeconds ) ]
                    , style "width" (String.fromFloat (remainingTimePercent timeRemaining) ++ "%")
                    ]
                    []
                ]
            ]
        , div [ class "text-center" ]
            [ div [ class "text-6xl font-bold text-amber-900" ]
                [ text (String.fromInt repsInCurrentRound) ]
            , if settings.mode == EndlessMode then
                text ""

              else
                let
                    currentRoundGoal : Int
                    currentRoundGoal =
                        min settings.repsPerMinute (repGoal - ((settings.currentRound - 1) * settings.repsPerMinute))
                in
                div [ class "text-xl text-amber-800" ]
                    [ text <| String.fromInt currentRoundGoal ++ " reps goal" ]
            ]
        , viewStats { currentReps = model.currentReps, lastWarningTime = model.lastWarningTime } settings
        ]


viewStats : { currentReps : Int, lastWarningTime : Maybe Time.Posix } -> EMOMSettings -> Html msg
viewStats model settings =
    let
        repsInCurrentRound : Int
        repsInCurrentRound =
            model.currentReps - (settings.currentRound - 1) * settings.repsPerMinute

        isAheadOfPace : Bool
        isAheadOfPace =
            not (isBehindPace model settings)

        paceMessage : String
        paceMessage =
            if repsInCurrentRound >= settings.repsPerMinute then
                "Round Complete! 🎉"

            else if isAheadOfPace then
                "Great Pace! 🎉"

            else
                "Keep Pushing! 🔥"
    in
    div [ class "text-center" ]
        [ div
            [ class "text-lg font-bold transition-colors"
            , classList
                [ ( "text-green-600", isAheadOfPace )
                , ( "text-amber-600", not isAheadOfPace && repsInCurrentRound > 0 )
                , ( "text-amber-800", repsInCurrentRound == 0 )
                ]
            ]
            [ text paceMessage ]
        , if settings.mode == EndlessMode then
            text ""

          else
            div [ class "text-sm mt-2 text-amber-800" ]
                [ text <| "Round " ++ String.fromInt settings.currentRound ++ " of " ++ String.fromInt settings.currentRound ]
        ]
