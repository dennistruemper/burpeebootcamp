module WorkoutResult exposing (StoredSessionType(..), WorkoutResult, decodeJson, encodeJson)

import Burpee
import Json.Decode
import Json.Encode
import Time


{-| Represents a practice session result.
Despite the name "WorkoutResult", this represents a practice session
following the "greasing the groove" methodology rather than an intense workout.
-}
type alias WorkoutResult =
    { reps : Int
    , repGoal : Maybe Int
    , burpee : Burpee.Burpee
    , timestamp : Time.Posix
    , sessionType : Maybe StoredSessionType
    }


type StoredSessionType
    = StoredAMRAP { duration : Int }
    | StoredEMOM
    | StoredWorkout
    | StoredFree


decodeJson : Json.Decode.Decoder WorkoutResult
decodeJson =
    Json.Decode.map5
        WorkoutResult
        (Json.Decode.field "reps" Json.Decode.int)
        (Json.Decode.maybe (Json.Decode.field "repGoal" Json.Decode.int))
        (Json.Decode.field "burpee" Burpee.decodeJson)
        (Json.Decode.field "timestamp" decodePosix)
        (Json.Decode.maybe (Json.Decode.field "sessionType" decodeSessionType))


decodePosix : Json.Decode.Decoder Time.Posix
decodePosix =
    Json.Decode.map Time.millisToPosix Json.Decode.int


decodeSessionType : Json.Decode.Decoder StoredSessionType
decodeSessionType =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
            (\str ->
                case str of
                    "AMRAP" ->
                        Json.Decode.map StoredAMRAP
                            (Json.Decode.field "duration" Json.Decode.int
                                |> Json.Decode.map (\duration -> { duration = duration })
                            )

                    "EMOM" ->
                        Json.Decode.succeed StoredEMOM

                    "Workout" ->
                        Json.Decode.succeed StoredWorkout

                    "Free" ->
                        Json.Decode.succeed StoredFree

                    _ ->
                        Json.Decode.fail "Invalid session type"
            )


encodeJson : WorkoutResult -> Json.Encode.Value
encodeJson workout =
    Json.Encode.object
        [ ( "reps", Json.Encode.int workout.reps )
        , ( "repGoal"
          , case workout.repGoal of
                Just repGoal ->
                    Json.Encode.int repGoal

                Nothing ->
                    Json.Encode.null
          )
        , ( "burpee", Burpee.encodeJson workout.burpee )
        , ( "timestamp", Json.Encode.int (Time.posixToMillis workout.timestamp) )
        , ( "sessionType"
          , case workout.sessionType of
                Just sessionType ->
                    encodeSessionType sessionType

                Nothing ->
                    Json.Encode.null
          )
        ]


encodeSessionType : StoredSessionType -> Json.Encode.Value
encodeSessionType sessionType =
    case sessionType of
        StoredAMRAP { duration } ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "AMRAP" )
                , ( "duration", Json.Encode.int duration )
                ]

        StoredEMOM ->
            Json.Encode.string "EMOM"

        StoredWorkout ->
            Json.Encode.string "Workout"

        StoredFree ->
            Json.Encode.string "Free"
