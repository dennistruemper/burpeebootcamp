module Evergreen.V15.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V15.Main.Layouts.Model
import Evergreen.V15.Main.Layouts.Msg
import Evergreen.V15.Main.Pages.Model
import Evergreen.V15.Main.Pages.Msg
import Evergreen.V15.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V15.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V15.Main.Layouts.Model.Model
    , shared : Evergreen.V15.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V15.Main.Pages.Msg.Msg
    | Layout Evergreen.V15.Main.Layouts.Msg.Msg
    | Shared Evergreen.V15.Shared.Msg
    | Batch (List Msg)
