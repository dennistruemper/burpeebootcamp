module Pages.Menu exposing (Model, Msg(..), page)

import Dict
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init () =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = NavigateTo Route.Path.Path


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NavigateTo path ->
            ( model
            , Effect.pushRoute
                { path = path
                , query = Dict.empty
                , hash = Nothing
                }
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Menu - BurpeeBootcamp"
    , body =
        [ div [ class "flex flex-col items-center w-full min-h-screen bg-gradient-to-b from-amber-50 to-amber-100" ]
            [ h1 [ class "mt-8 mb-8 font-semibold font-lora text-2xl text-amber-800" ]
                [ text "BurpeeBootcamp Menu" ]
            , div [ class "flex flex-col gap-4 w-full max-w-md px-4" ]
                [ menuButton "Counter" Route.Path.Counter
                , menuButton "Pick Variant" Route.Path.PickVariant
                , menuButton "Results" Route.Path.Results
                ]
            ]
        ]
    }


menuButton : String -> Route.Path.Path -> Html Msg
menuButton label path =
    button
        [ class "w-full px-6 py-4 rounded-lg bg-amber-600 hover:bg-amber-700 text-white font-bold shadow-lg transform transition hover:scale-105 active:bg-amber-800/30"
        , onClick (NavigateTo path)
        ]
        [ text label ]
