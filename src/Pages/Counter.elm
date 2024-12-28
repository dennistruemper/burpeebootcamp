module Pages.Counter exposing (Model, Msg(..), page)

import Bridge
import Effect exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Lamdera
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
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


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        IncrementReps ->
            ( { model | currentReps = model.currentReps + 1 }
            , Effect.none
            )

        ResetCounter ->
            ( { model | currentReps = 0 }
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
        [ div [ class "flex flex-col items-center w-full h-full" ]
            [ h1 [ class "mt-2 mb-2 font-semibold font-lora text-xl text-amber-800" ]
                [ text "BurpeeBootcamp" ]
            , div
                [ class "w-screen h-[60vh] flex flex-col items-center justify-center bg-amber-100/30 cursor-pointer select-none touch-manipulation gap-4"
                , onClick IncrementReps
                ]
                [ div
                    [ class "flex flex-col items-center gap-2"
                    , classList
                        [ ( "animate-scale-count", model.currentReps > 0 )
                        ]
                    ]
                    [ div [ class "text-6xl font-bold text-amber-900" ]
                        [ text (String.fromInt model.currentReps) ]
                    , div [ class "text-2xl opacity-80 text-amber-800" ]
                        [ text " / 20 reps" ]
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
            , div
                [ class "mt-4 px-6 py-3 rounded-lg bg-amber-800/20 cursor-pointer select-none text-sm text-amber-900 active:bg-amber-800/30"
                , onClick ResetCounter
                ]
                [ text "Reset Counter" ]
            ]
        ]
    }
