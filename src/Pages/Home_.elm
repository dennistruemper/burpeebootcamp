module Pages.Home_ exposing (Model, Msg(..), page)

import Bridge
import Burpee
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
        { init = init shared
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    {}


init : Shared.Model -> () -> ( Model, Effect Msg )
init shared _ =
    ( {}
    , Effect.none
    )



-- UPDATE


monthToNumber : Time.Month -> Int
monthToNumber month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


toIsoDate : Time.Posix -> String
toIsoDate time =
    let
        year =
            String.fromInt (Time.toYear Time.utc time)

        month =
            String.padLeft 2 '0' (String.fromInt (monthToNumber (Time.toMonth Time.utc time)))

        day =
            String.padLeft 2 '0' (String.fromInt (Time.toDay Time.utc time))

        hour =
            String.padLeft 2 '0' (String.fromInt (Time.toHour Time.utc time))

        minute =
            String.padLeft 2 '0' (String.fromInt (Time.toMinute Time.utc time))

        second =
            String.padLeft 2 '0' (String.fromInt (Time.toSecond Time.utc time))

        millisecond =
            String.padLeft 3 '0' (String.fromInt (Time.toMillis Time.utc time))
    in
    year ++ "-" ++ month ++ "-" ++ day ++ "T" ++ hour ++ ":" ++ minute ++ ":" ++ second ++ "." ++ millisecond ++ "Z"


type Msg
    = Redirect
    | NoOp


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        Redirect ->
            ( model
            , case shared.initializing of
                True ->
                    Effect.none

                False ->
                    case shared.currentBurpee of
                        Just _ ->
                            Effect.pushRoutePath Route.Path.Counter

                        Nothing ->
                            Effect.pushRoute { path = Route.Path.PickVariant, query = Dict.fromList [ ( "first", "true" ) ], hash = Nothing }
            )

        NoOp ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map (\_ -> Redirect) (Time.every 10 identity)



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    if shared.initializing then
        { title = "BurpeeBootcamp"
        , body =
            [ div []
                [ text "Loading..." ]
            ]
        }

    else
        case shared.currentBurpee of
            Just burpee ->
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
