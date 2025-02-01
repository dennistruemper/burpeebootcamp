module Evergreen.V16.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V16.Main.Layouts.Model
import Evergreen.V16.Main.Layouts.Msg
import Evergreen.V16.Main.Pages.Model
import Evergreen.V16.Main.Pages.Msg
import Evergreen.V16.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V16.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V16.Main.Layouts.Model.Model
    , shared : Evergreen.V16.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V16.Main.Pages.Msg.Msg
    | Layout Evergreen.V16.Main.Layouts.Msg.Msg
    | Shared Evergreen.V16.Shared.Msg
    | Batch (List Msg)
