port module Ports exposing (InitData, ToElm(..), decodeMsg, toElm, toJs)

import Burpee exposing (Burpee)
import Json.Decode
import Json.Encode
import WorkoutResult exposing (WorkoutResult)


type ToElm
    = NoOp
    | UnknownMessage String
    | GotInitData InitData


type alias InitData =
    { workoutHistory : List WorkoutResult
    , currentBurpeeVariant : Maybe Burpee
    , version : String
    }


port toElm : (String -> msg) -> Sub msg



-- encode error


decodeMsg : String -> ToElm
decodeMsg json =
    case Json.Decode.decodeString (Json.Decode.field "tag" Json.Decode.string) json of
        Ok "NoOp" ->
            NoOp

        Ok "InitData" ->
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


initDataDecoder : Json.Decode.Decoder InitData
initDataDecoder =
    let
        burpeeDecoder : Json.Decode.Decoder (Maybe Burpee)
        burpeeDecoder =
            Json.Decode.field "currentBurpeeVariant" (Json.Decode.maybe Burpee.decodeJson)

        workoutHistoryDecoder : Json.Decode.Decoder (List WorkoutResult)
        workoutHistoryDecoder =
            Json.Decode.field "workoutHistory" (Json.Decode.list WorkoutResult.decodeJson)

        versionDecoder : Json.Decode.Decoder String
        versionDecoder =
            Json.Decode.field "version" Json.Decode.string
    in
    Json.Decode.field "data"
        (Json.Decode.map3 InitData
            workoutHistoryDecoder
            burpeeDecoder
            versionDecoder
        )
