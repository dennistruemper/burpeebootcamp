module Pages.Counter exposing (Model, Msg(..), page)

import Bridge
import Burpee exposing (Burpee)
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
        { init = init
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    { currentReps : Int
    }


init : () -> ( Model, Effect Msg )
init _ =
    ( { currentReps = 0 }
    , Effect.none
    )



-- UPDATE


type Msg
    = IncrementReps
    | ResetCounter
    | GotWorkoutFinishedTime Time.Posix
    | GetWorkoutFinishedTime


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
                    }
                , Effect.replaceRoutePath Route.Path.Home_
                ]
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
        [ div [ class "flex flex-col items-center w-full h-screen" ]
            [ h1 [ class "mt-2 mb-2 font-semibold font-lora text-xl text-amber-800" ]
                [ text "BurpeeBootcamp" ]
            , details [ class "mb-4" ]
                [ summary [ class "text-sm text-amber-800 opacity-60 cursor-pointer select-none" ]
                    [ text "Show options" ]
                , div [ class "flex gap-2 mt-2" ]
                    [ button
                        [ class "px-6 py-3 rounded-lg bg-amber-800/20 cursor-pointer select-none text-sm text-amber-900 active:bg-amber-800/30"
                        , onClick ResetCounter
                        ]
                        [ text "Reset Counter" ]
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
                        [ text <| " / " ++ String.fromInt shared.currentRepGoal ++ " reps" ]
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
            ]
        ]
    }
