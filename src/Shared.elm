module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions

-}

import Burpee exposing (Burpee)
import Effect exposing (Effect)
import Json.Decode
import Ports
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg



-- FLAGS


type alias Flags =
    {}


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.succeed {}



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult route =
    ( { currentBurpee = Nothing, currentRepGoal = 10, workoutHistory = [], initializing = True }
    , Effect.none
    )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        Shared.Msg.BurpeePicked burpee ->
            ( { model | currentBurpee = Just burpee }
            , Effect.none
            )

        Shared.Msg.StoreWorkoutResult result ->
            case model.currentBurpee of
                Just burpee ->
                    ( { model
                        | workoutHistory =
                            { reps = result.reps
                            , burpee = burpee
                            , timestamp = result.timestamp
                            }
                                :: model.workoutHistory
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        Shared.Msg.GotPortMessage rawMessage ->
            let
                _ =
                    Debug.log "rawMessage" rawMessage
            in
            case Ports.decodeMsg rawMessage of
                Ports.GotInitData data ->
                    let
                        _ =
                            Debug.log "data" data
                    in
                    ( { model
                        | currentBurpee = data.currentBurpeeVariant
                        , initializing = False
                      }
                    , Effect.none
                    )

                Ports.NoOp ->
                    let
                        _ =
                            Debug.log "NoOp" "NoOp"
                    in
                    ( model, Effect.none )

                Ports.UnknownMessage message ->
                    let
                        _ =
                            Debug.log "UnknownMessage" message
                    in
                    ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.batch [ Ports.toElm Shared.Msg.GotPortMessage ]
