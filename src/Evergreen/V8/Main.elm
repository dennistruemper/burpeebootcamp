module Evergreen.V8.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V8.Main.Layouts.Model
import Evergreen.V8.Main.Layouts.Msg
import Evergreen.V8.Main.Pages.Model
import Evergreen.V8.Main.Pages.Msg
import Evergreen.V8.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V8.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V8.Main.Layouts.Model.Model
    , shared : Evergreen.V8.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V8.Main.Pages.Msg.Msg
    | Layout Evergreen.V8.Main.Layouts.Msg.Msg
    | Shared Evergreen.V8.Shared.Msg
    | Batch (List Msg)
