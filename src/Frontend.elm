module Frontend exposing (..)

import Browser
import Browser.Navigation
import Json.Encode
import Lamdera
import Main as ElmLand
import Shared.Msg
import Task
import Time
import Types exposing (FrontendModel, FrontendMsg, ToFrontend(..))
import Url


type alias Model =
    FrontendModel


app :
    { init :
        Lamdera.Url
        -> Browser.Navigation.Key
        -> ( ElmLand.Model, Cmd ElmLand.Msg )
    , onUrlChange : Url.Url -> ElmLand.Msg
    , onUrlRequest : Browser.UrlRequest -> ElmLand.Msg
    , subscriptions : ElmLand.Model -> Sub ElmLand.Msg
    , update :
        ElmLand.Msg -> ElmLand.Model -> ( ElmLand.Model, Cmd ElmLand.Msg )
    , updateFromBackend :
        ToFrontend -> ElmLand.Model -> ( ElmLand.Model, Cmd ElmLand.Msg )
    , view : ElmLand.Model -> Browser.Document ElmLand.Msg
    }
app =
    Lamdera.frontend
        { init = ElmLand.init Json.Encode.null
        , onUrlRequest = ElmLand.UrlRequested
        , onUrlChange = ElmLand.UrlChanged
        , update = ElmLand.update
        , updateFromBackend = updateFromBackend
        , subscriptions = ElmLand.subscriptions
        , view = ElmLand.view
        }


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOp ->
            ( model, sendSharedMsg Shared.Msg.NoOp )


sendSharedMsg : Shared.Msg.Msg -> Cmd FrontendMsg
sendSharedMsg msg =
    Time.now |> Task.perform (always (ElmLand.Shared msg))
