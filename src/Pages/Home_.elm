module Pages.Home_ exposing (Model, Msg(..), page)

import Bridge
import Dict
import Effect exposing (Effect)
import Env
import Html exposing (div, text)
import Lamdera
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import Time
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared _ =
    Page.new
        { init = init
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    { dummyEnvValue : String
    }


init : () -> ( Model, Effect Msg )
init _ =
    ( { dummyEnvValue = Env.dummyConfigItem
      }
    , Effect.sendCmd (Lamdera.sendToBackend Bridge.NoOp)
    )



-- UPDATE


type Msg
    = Redirect


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        Redirect ->
            ( model
            , if shared.initializing then
                Effect.none

              else
                case shared.currentBurpee of
                    Just _ ->
                        Effect.replaceRoutePath Route.Path.Counter

                    Nothing ->
                        Effect.replaceRoute { path = Route.Path.PickVariant, query = Dict.fromList [ ( "first", "true" ) ], hash = Nothing }
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.map (\_ -> Redirect) (Time.every 10 identity)



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared _ =
    if shared.initializing then
        { title = "BurpeeBootcamp"
        , body =
            [ div []
                [ text "Loading..." ]
            ]
        }

    else
        case shared.currentBurpee of
            Just _ ->
                { title = "BurpeeBootcamp"
                , body =
                    [ div []
                        [ text "Redirecting to counter..." ]
                    ]
                }

            Nothing ->
                { title = "BurpeeBootcamp"
                , body =
                    [ div []
                        [ text "Redirecting to burpee picker..." ]
                    ]
                }
