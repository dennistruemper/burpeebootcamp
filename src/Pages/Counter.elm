module Pages.Counter exposing (Model, Msg(..), page)

import Bridge
import Burpee exposing (Burpee)
import Dict
import Effect exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Lamdera
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import Time
import View exposing (View)


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
    let
        lastWorkout =
            shared.workoutHistory |> List.sortBy (\workout -> workout.timestamp |> Time.posixToMillis) |> List.reverse |> List.head

        _ =
            Debug.log "lastWorkout" lastWorkout

        daysSinceLastWorkout =
            case lastWorkout of
                Just workout ->
                    Time.posixToMillis shared.currentTime
                        - Time.posixToMillis workout.timestamp
                        |> (\ms ->
                                let
                                    _ =
                                        Debug.log "ms" ms
                                in
                                toFloat ms / (1000 * 60 * 60 * 24)
                           )
                        |> floor

                Nothing ->
                    Debug.log "No last workout" 999

        _ =
            Debug.log "daysSinceLastWorkout" daysSinceLastWorkout

        wasGoalReached =
            case lastWorkout of
                Just workout ->
                    Maybe.map2 (\goal reps -> reps >= goal) workout.repGoal (Just workout.reps)
                        |> Maybe.withDefault False

                Nothing ->
                    False

        adjustedGoal =
            if daysSinceLastWorkout <= 1 then
                -- Yesterday's workout
                case lastWorkout of
                    Just lw ->
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

        _ =
            Debug.log "adjustedGoal" adjustedGoal
    in
    case model.overwriteRepGoal of
        Just repGoal ->
            Basics.max 10 repGoal

        Nothing ->
            Basics.max 10 adjustedGoal


type alias Model =
    { currentReps : Int
    , overwriteRepGoal : Maybe Int
    , initialShowWelcomeModal : Bool
    }


init : Shared.Model -> Route () -> () -> ( Model, Effect Msg )
init shared route _ =
    ( { currentReps = 0
      , overwriteRepGoal = Dict.get "repGoal" route.query |> Maybe.map String.toInt |> Maybe.withDefault Nothing
      , initialShowWelcomeModal = List.isEmpty shared.workoutHistory
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = IncrementReps
    | ResetCounter
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime
    | ChangeToMenu
    | CloseWelcomeModal


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        IncrementReps ->
            ( { model | currentReps = model.currentReps + 1 }
            , Effect.none
            )

        ResetCounter ->
            ( { model | currentReps = 0 }
            , Effect.none
            )

        GetWorkoutFinishedTime ->
            ( model
            , Effect.getTime GotWorkoutFinishedTime
            )

        GotWorkoutFinishedTime time ->
            ( model
            , Effect.batch
                [ Effect.storeWorkoutResult
                    { reps = model.currentReps
                    , burpee = Maybe.withDefault Burpee.default shared.currentBurpee
                    , timestamp = time
                    , repGoal = Just (calculateNextGoal shared model)
                    }
                , Effect.replaceRoutePath Route.Path.Results
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "BurpeeBootcamp"
    , body =
        case shared.initializing of
            True ->
                [ text "Initializing..." ]

            False ->
                let
                    updatedShowWelcomeModal =
                        List.isEmpty shared.workoutHistory
                in
                [ div [ class "flex flex-col items-center w-full h-screen relative" ]
                    [ h1 [ class "mt-2 mb-2 font-semibold font-lora text-xl text-amber-800" ]
                        [ img
                            [ src "/logo/logo.png"
                            , class "h-32" -- Adjust height as needed
                            , alt "BurpeeBootcamp"
                            ]
                            []
                        ]
                    , details [ class "mb-4" ]
                        [ summary [ class "text-lg mt-4 text-amber-800 font-semibold hover:text-amber-900 cursor-pointer select-none border border-amber-800/30 rounded px-3 py-1" ]
                            [ text "Show options" ]
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
                                [ class "px-6 py-3 rounded-lg bg-green-700/20 cursor-pointer select-none text-sm text-green-900 active:bg-green-700/30"
                                , onClick GetWorkoutFinishedTime
                                ]
                                [ text "Done" ]
                            ]
                        ]
                    , div
                        [ class "w-screen flex-1 flex flex-col items-center justify-center bg-amber-100/30 cursor-pointer select-none touch-manipulation relative"
                        , onClick IncrementReps
                        ]
                        [ div [ class "absolute inset-0 grid grid-cols-2 xl:grid-cols-4 gap-4 place-items-center place-content-center pointer-events-none overflow-hidden" ]
                            (List.repeat 20
                                (div [ class "text-amber-800/5 text-4xl font-bold rotate-[-20deg] text-center" ]
                                    [ text "NOSE TAP AREA" ]
                                )
                            )
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
                            , div [ class "text-2xl opacity-80 text-amber-800" ]
                                [ text <| " / " ++ String.fromInt (calculateNextGoal shared model) ++ " reps" ]
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
                                    , p [ class "italic mt-4" ]
                                        [ text "Let's grow stronger together! 🌱 → 🌳" ]
                                    ]
                                , button
                                    [ class "mt-6 w-full px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors"
                                    , onClick CloseWelcomeModal
                                    ]
                                    [ text "Got it, let's start! 💪" ]
                                ]
                            ]

                      else
                        text ""
                    ]
                ]
    }
