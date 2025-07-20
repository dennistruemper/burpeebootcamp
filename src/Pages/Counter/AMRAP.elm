module Pages.Counter.AMRAP exposing
    ( AMRAPSettings
    , AMRAPStatus(..)
    , defaultSettings
    , findBestScore
    , remainingTime
    , viewConfig
    , viewStatus
    )

import Html exposing (Html, button, div, h3, input, label, span, text)
import Html.Attributes exposing (class, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Shared
import Time
import WorkoutResult



-- TYPES


type AMRAPStatus
    = NotStarted
    | Running
    | Finished


type alias AMRAPSettings =
    { duration : Int -- in minutes
    , startTime : Time.Posix
    , currentTime : Time.Posix
    , status : AMRAPStatus
    , showSettings : Bool
    , previousBest : Maybe Int
    }



-- HELPER FUNCTIONS


defaultSettings : AMRAPSettings
defaultSettings =
    { duration = 20
    , startTime = Time.millisToPosix 0
    , currentTime = Time.millisToPosix 0
    , status = NotStarted
    , showSettings = True
    , previousBest = Nothing
    }


findBestScore : List WorkoutResult.WorkoutResult -> Int -> Maybe Int
findBestScore history selectedDuration =
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


remainingTime : AMRAPSettings -> ( Int, Int )
remainingTime settings =
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



-- VIEW FUNCTIONS


viewConfig : (AMRAPSettings -> msg) -> msg -> Shared.Model -> AMRAPSettings -> Html msg
viewConfig configureAMRAPMsg startAMRAPMsg shared settings =
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
    div
        [ class "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        ]
        [ div
            [ class "bg-white p-6 rounded-lg shadow-xl max-w-sm mx-4"
            ]
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
                    , text """
                        Remember: Quality over quantity! Maintain proper form throughout
                        the session to prevent injury. It's better to do fewer reps
                        with good form than many with poor form.
                      """
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
                        , Html.Attributes.min "1"
                        , Html.Attributes.max "60"
                        , Html.Attributes.step "1"
                        , value (String.fromInt settings.duration)
                        , onInput
                            (\str ->
                                let
                                    newDuration : Int
                                    newDuration =
                                        Maybe.withDefault settings.duration (String.toInt str)

                                    previousBest : Maybe Int
                                    previousBest =
                                        findBestScore shared.workoutHistory newDuration
                                in
                                configureAMRAPMsg
                                    { settings
                                        | duration = newDuration
                                        , previousBest = previousBest
                                        , showSettings = True -- Ensure modal stays open
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
                    , onClick startAMRAPMsg
                    ]
                    [ text "Start AMRAP" ]
                ]
            ]
        ]


viewStatus : { currentReps : Int } -> AMRAPSettings -> Html msg
viewStatus model settings =
    let
        ( timeRemaining, progress ) =
            remainingTime settings
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
