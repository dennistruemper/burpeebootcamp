module Evergreen.V6.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V6.Main.Layouts.Model
import Evergreen.V6.Main.Layouts.Msg
import Evergreen.V6.Main.Pages.Model
import Evergreen.V6.Main.Pages.Msg
import Evergreen.V6.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V6.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V6.Main.Layouts.Model.Model
    , shared : Evergreen.V6.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V6.Main.Pages.Msg.Msg
    | Layout Evergreen.V6.Main.Layouts.Msg.Msg
    | Shared Evergreen.V6.Shared.Msg
    | Batch (List Msg)
