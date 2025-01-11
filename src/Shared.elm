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
import Env
import Json.Decode
import Ports
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg
import Time
import WorkoutResult exposing (WorkoutResult)



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
    let
        timeEffect =
            case Env.mode of
                Env.Development ->
                    Effect.getTime Shared.Msg.GotTimeForFakedata

                Env.Production ->
                    Effect.none
    in
    ( { currentBurpee = Nothing, currentRepGoal = 10, workoutHistory = [], initializing = True }
    , timeEffect
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
                    ( { model
                        | currentBurpee = data.currentBurpeeVariant
                        , workoutHistory =
                            if List.isEmpty data.workoutHistory then
                                model.workoutHistory

                            else
                                data.workoutHistory
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

        Shared.Msg.NoOp ->
            ( model, Effect.none )

        Shared.Msg.GotTime time ->
            ( model, Effect.none )

        Shared.Msg.GotTimeForFakedata time ->
            ( { model | workoutHistory = generateFakeData time }, Effect.none )


generateFakeData : Time.Posix -> List WorkoutResult
generateFakeData time =
    let
        msPerDay =
            86400000

        now =
            Time.posixToMillis time
    in
    [ { reps = 12
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 1) |> Time.millisToPosix -- Yesterday
      }
    , { reps = 13
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 2) |> Time.millisToPosix -- 2 days ago
      }
    , { reps = 10
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 3) |> Time.millisToPosix -- 3 days ago
      }

    -- 4 days ago intentionally missing
    , { reps = 8
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 5) |> Time.millisToPosix -- 5 days ago
      }
    , { reps = 5
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 6) |> Time.millisToPosix -- 6 days ago
      }
    , { reps = 5
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 8) |> Time.millisToPosix -- 6 days ago
      }
    , { reps = 5
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 10) |> Time.millisToPosix -- 6 days ago
      }
    , { reps = 15
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 35) |> Time.millisToPosix -- 35 days ago
      }
    , { reps = 12
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 36) |> Time.millisToPosix -- 36 days ago
      }

    -- 37-39 days ago intentionally missing
    , { reps = 14
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 40) |> Time.millisToPosix -- 40 days ago
      }
    , { reps = 11
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 41) |> Time.millisToPosix -- 41 days ago
      }
    , { reps = 1111
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 42) |> Time.millisToPosix -- 41 days ago
      }

    -- 42-44 days ago intentionally missing
    , { reps = 13
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 45) |> Time.millisToPosix -- 45 days ago
      }
    , { reps = 16
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 46) |> Time.millisToPosix -- 46 days ago
      }
    , { reps = 12
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 47) |> Time.millisToPosix -- 47 days ago
      }

    -- 48-50 days ago intentionally missing
    , { reps = 10
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 51) |> Time.millisToPosix -- 51 days ago
      }
    , { reps = 9
      , burpee = Burpee.default
      , timestamp = now - (msPerDay * 52) |> Time.millisToPosix -- 52 days ago
      }
    ]



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.batch [ Ports.toElm Shared.Msg.GotPortMessage ]
