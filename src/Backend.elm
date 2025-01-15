module Backend exposing (..)

import Bridge exposing (ToBackend)
import Dict
import Lamdera exposing (ClientId, SessionId)
import Types exposing (BackendModel, BackendMsg(..))


type alias Model =
    BackendModel


app :
    { init : ( Model, Cmd BackendMsg )
    , subscriptions : Model -> Sub BackendMsg
    , update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
    , updateFromFrontend :
        SessionId
        -> ClientId
        -> ToBackend
        -> Model
        -> ( Model, Cmd BackendMsg )
    }
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \_ -> Lamdera.onConnect OnConnect
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { users = Dict.empty }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        OnConnect _ _ ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId _ msg model =
    case msg of
        Bridge.NoOp ->
            ( model, Lamdera.sendToFrontend sessionId Types.NoOp )
