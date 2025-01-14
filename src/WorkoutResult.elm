module WorkoutResult exposing (WorkoutResult, decodeJson, encodeJson)

import Burpee exposing (Burpee)
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
    , burpee : Burpee
    , timestamp : Time.Posix
    }


decodeJson : Json.Decode.Decoder WorkoutResult
decodeJson =
    Json.Decode.map4
        WorkoutResult
        (Json.Decode.field "reps" Json.Decode.int)
        (Json.Decode.maybe (Json.Decode.field "repGoal" Json.Decode.int))
        (Json.Decode.field "burpee" Burpee.decodeJson)
        (Json.Decode.field "timestamp" decodePosix)


decodePosix : Json.Decode.Decoder Time.Posix
decodePosix =
    Json.Decode.map Time.millisToPosix Json.Decode.int


encodeJson : WorkoutResult -> Json.Encode.Value
encodeJson workout =
    Json.Encode.object
        [ ( "reps", Json.Encode.int workout.reps )
        , case workout.repGoal of
            Just repGoal ->
                ( "repGoal", Json.Encode.int repGoal )

            Nothing ->
                ( "repGoal", Json.Encode.null )
        , ( "burpee", Burpee.encodeJson workout.burpee )
        , ( "timestamp", Json.Encode.int (Time.posixToMillis workout.timestamp) )
        ]
