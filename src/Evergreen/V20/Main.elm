module Evergreen.V20.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V20.Main.Layouts.Model
import Evergreen.V20.Main.Layouts.Msg
import Evergreen.V20.Main.Pages.Model
import Evergreen.V20.Main.Pages.Msg
import Evergreen.V20.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V20.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V20.Main.Layouts.Model.Model
    , shared : Evergreen.V20.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V20.Main.Pages.Msg.Msg
    | Layout Evergreen.V20.Main.Layouts.Msg.Msg
    | Shared Evergreen.V20.Shared.Msg
    | Batch (List Msg)
