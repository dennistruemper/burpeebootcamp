port module Ports exposing (ToElm(..), decodeMsg, toElm, toJs)

import Bridge
import Burpee exposing (Burpee)
import Json.Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode
import Serialize as S


type ToElm
    = NoOp
    | UnknownMessage String
    | GotInitData InitData


type alias InitData =
    { currentBurpeeVariant : Maybe Burpee
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


initDataCodec : S.Codec e InitData
initDataCodec =
    S.record InitData |> S.field .currentBurpeeVariant (S.maybe Burpee.codec) |> S.finishRecord


initDataDecoder =
    Json.Decode.field "data"
        (Json.Decode.map InitData
            (Json.Decode.field "currentBurpeeVariant"
                (Json.Decode.maybe Burpee.decodeJson)
            )
        )
