module WorkoutResult exposing (WorkoutResult, decodeJson, encodeJson)

import Burpee exposing (Burpee)
import Json.Decode
import Json.Encode
import Time


type alias WorkoutResult =
    { reps : Int
    , burpee : Burpee
    , timestamp : Time.Posix
    }


decodeJson : Json.Decode.Decoder WorkoutResult
decodeJson =
    Json.Decode.map3
        WorkoutResult
        (Json.Decode.field "reps" Json.Decode.int)
        (Json.Decode.field "burpee" Burpee.decodeJson)
        (Json.Decode.field "timestamp" decodePosix)


decodePosix : Json.Decode.Decoder Time.Posix
decodePosix =
    Json.Decode.map Time.millisToPosix Json.Decode.int


encodeJson : WorkoutResult -> Json.Encode.Value
encodeJson workout =
    Json.Encode.object
        [ ( "reps", Json.Encode.int workout.reps )
        , ( "burpee", Burpee.encodeJson workout.burpee )
        , ( "timestamp", Json.Encode.int (Time.posixToMillis workout.timestamp) )
        ]
