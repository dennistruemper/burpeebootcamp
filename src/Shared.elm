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
        Shared.Msg.StoreWorkoutResult result ->
            case model.currentBurpee of
                Just burpee ->
                    let
                        workout =
                            { reps = result.reps
                            , burpee = burpee
                            , timestamp = result.timestamp
                            }
                    in
                    ( { model
                        | workoutHistory = workout :: model.workoutHistory
                      }
                    , Effect.batch
                        [ Effect.storeWorkout workout
                        , Effect.calculateRepGoal Shared.Msg.GotTimeForRepGoalCalculation
                        ]
                    )

                Nothing ->
                    ( model, Effect.none )

        Shared.Msg.GotPortMessage rawMessage ->
            case Ports.decodeMsg rawMessage of
                Ports.GotInitData data ->
                    let
                        _ =
                            Debug.log "GotInitData" data
                    in
                    ( { model
                        | currentBurpee = data.currentBurpeeVariant
                        , workoutHistory = data.workoutHistory
                        , initializing = False
                      }
                    , Effect.calculateRepGoal Shared.Msg.GotTimeForRepGoalCalculation
                    )

                Ports.NoOp ->
                    ( model, Effect.none )

                Ports.UnknownMessage _ ->
                    ( model, Effect.none )

        Shared.Msg.GotTimeForRepGoalCalculation time ->
            ( model, Effect.none )

        Shared.Msg.BurpeePicked burpee ->
            ( { model | currentBurpee = Just burpee }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.batch [ Ports.toElm Shared.Msg.GotPortMessage ]
