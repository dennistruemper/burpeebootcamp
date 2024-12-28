module Pages.Home_ exposing (Model, Msg(..), page)

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
        [ node "style" [] [ text """
            @import url('https://fonts.googleapis.com/css2?family=Lora:wght@600&family=Nunito+Sans&display=swap');

            html {
                height: 100%;
                color: #8B4513;
                background: linear-gradient(#E6D5B8, #D2B48C);
                -webkit-tap-highlight-color: transparent;
            }
            body {
                display: flex;
                flex-direction: column;
                margin: 0;
                justify-content: flex-start;
                align-items: center;
                min-height: -webkit-fill-available;
                height: 100vh;
                font-family: 'Nunito Sans';
                padding: 0;
                box-sizing: border-box;
            }
            h1 {
                margin: 0.5rem 0;
                font-weight: 600 !important;
                font-family: 'Lora';
                font-size: 1.5rem;
                color: #8B4513;
            }
            .nose-button {
                width: 100vw;
                height: 60vh;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                background-color: rgba(210, 180, 140, 0.3);
                cursor: pointer;
                user-select: none;
                -webkit-user-select: none;
                transition: background-color 0.2s;
                margin: 0;
                touch-action: manipulation;
                gap: 1rem;
            }
            .nose-button:active {
                background-color: rgba(210, 180, 140, 0.5);
            }
            .counter {
                font-size: 5rem;
                font-weight: bold;
                animation: scaleCount 0.3s ease-out;
                display: flex;
                flex-direction: column;
                align-items: center;
                gap: 0.5rem;
                color: #8B4513;
            }
            .reps-count {
                font-size: 2rem;
                opacity: 0.8;
                font-weight: normal;
                color: #A0522D;
            }
            @keyframes scaleCount {
                0% { transform: scale(1); }
                50% { transform: scale(1.2); }
                100% { transform: scale(1); }
            }
            .tap-text {
                font-size: 1.2rem;
                opacity: 0;
                transition: opacity 0.3s;
                color: #8B4513;
            }
            .tap-text.pulsing {
                opacity: 1;
                animation: pulse 1.5s ease-in-out infinite;
            }
            @keyframes pulse {
                0% { transform: scale(1); opacity: 1; }
                50% { transform: scale(1.1); opacity: 0.3; }
                100% { transform: scale(1); opacity: 1; }
            }
            .reset-button {
                cursor: pointer;
                background-color: rgba(139, 69, 19, 0.2);
                padding: 0.8rem 1.6rem;
                border-radius: 8px;
                user-select: none;
                -webkit-user-select: none;
                transition: background-color 0.2s;
                margin-top: 1rem;
                font-size: 0.9rem;
                color: #8B4513;
            }
            .reset-button:active {
                background-color: rgba(139, 69, 19, 0.3);
            }
            .container {
                display: flex;
                flex-direction: column;
                align-items: center;
                width: 100%;
                height: 100%;
            }
            """ ]
        , div [ class "container" ]
            [ h1 [] [ text "BurpeeBootcamp" ]
            , div
                [ class "nose-button"
                , onClick IncrementReps
                ]
                [ div
                    [ class "counter"
                    , style "animation-name"
                        (if model.currentReps > 0 then
                            "scaleCount"

                         else
                            "none"
                        )
                    ]
                    [ text (String.fromInt model.currentReps)
                    , div [ class "reps-count" ]
                        [ text " / 20 reps" ]
                    ]
                , div
                    [ class "tap-text"
                    , classList [ ( "pulsing", model.currentReps == 0 ) ]
                    ]
                    [ text "TAP TO COUNT" ]
                ]
            , div
                [ class "reset-button"
                , onClick ResetCounter
                ]
                [ text "Reset Counter" ]
            ]
        ]
    }
