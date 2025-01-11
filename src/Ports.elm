port module Ports exposing (ToElm(..), decodeMsg, toElm, toJs)

import Bridge
import Burpee exposing (Burpee)
import Json.Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode
import Serialize as S
import Time
import WorkoutResult exposing (WorkoutResult)


type ToElm
    = NoOp
    | UnknownMessage String
    | GotInitData InitData


type ToJS
    = StoreBurpeeVariant Burpee
    | StoreWorkout WorkoutResult


type alias InitData =
    { workoutHistory : List WorkoutResult
    , currentBurpeeVariant : Maybe Burpee
    }


port toElm : (String -> msg) -> Sub msg


formatSerializeError : String -> S.Error e -> String
formatSerializeError field error =
    "Could not decode " ++ field ++ ": "



-- encode error


decodeMsg : String -> ToElm
decodeMsg json =
    case Json.Decode.decodeString (Json.Decode.field "tag" Json.Decode.string) json of
        Ok "NoOp" ->
            NoOp

        Ok "InitData" ->
            let
                burpeeDecoder =
                    Json.Decode.field "tag" Json.Decode.string
                        |> Json.Decode.andThen
                            (\tag ->
                                if tag == "Burpee" then
                                    Json.Decode.field "data" Burpee.decodeJson

                                else
                                    Json.Decode.fail "Expected Burpee tag"
                            )
            in
            case Json.Decode.decodeString initDataDecoder json of
                Ok initData ->
                    GotInitData initData

                Err message ->
                    UnknownMessage (formatError "initData" message)

        Err message ->
            UnknownMessage (formatError "tag" message)

        Ok tagname ->
            UnknownMessage <| "tag is unknown: " ++ tagname


formatError : String -> Json.Decode.Error -> String
formatError field error =
    "Could not decode" ++ field ++ ": " ++ Json.Decode.errorToString error


port toJs : { tag : String, data : Json.Encode.Value } -> Cmd msg


initDataDecoder =
    let
        burpeeDecoder =
            Json.Decode.field "currentBurpeeVariant" (Json.Decode.maybe Burpee.decodeJson)

        workoutHistoryDecoder =
            Json.Decode.field "workoutHistory" (Json.Decode.list WorkoutResult.decodeJson)
    in
    Json.Decode.field "data"
        (Json.Decode.map2 InitData
            workoutHistoryDecoder
            burpeeDecoder
        )


encodeToJS : ToJS -> Json.Encode.Value
encodeToJS msg =
    case msg of
        StoreBurpeeVariant burpee ->
            Json.Encode.object
                [ ( "tag", Json.Encode.string "StoreBurpeeVariant" )
                , ( "data", Burpee.encodeJson burpee )
                ]

        StoreWorkout workout ->
            Json.Encode.object
                [ ( "tag", Json.Encode.string "StoreWorkout" )
                , ( "data"
                  , Json.Encode.object
                        [ ( "reps", Json.Encode.int workout.reps )
                        , ( "burpee", Burpee.encodeJson workout.burpee )
                        , ( "timestamp", Json.Encode.int (Time.posixToMillis workout.timestamp) )
                        ]
                  )
                ]


decodeInitData : Json.Decode.Decoder InitData
decodeInitData =
    Json.Decode.map2 InitData
        (Json.Decode.field "workoutHistory" (Json.Decode.list WorkoutResult.decodeJson))
        (Json.Decode.field "currentBurpeeVariant" (Json.Decode.nullable Burpee.decodeJson))
