module Evergreen.V3.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V3.Main.Layouts.Model
import Evergreen.V3.Main.Layouts.Msg
import Evergreen.V3.Main.Pages.Model
import Evergreen.V3.Main.Pages.Msg
import Evergreen.V3.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V3.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V3.Main.Layouts.Model.Model
    , shared : Evergreen.V3.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V3.Main.Pages.Msg.Msg
    | Layout Evergreen.V3.Main.Layouts.Msg.Msg
    | Shared Evergreen.V3.Shared.Msg
    | Batch (List Msg)
