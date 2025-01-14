module Evergreen.V9.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V9.Main.Layouts.Model
import Evergreen.V9.Main.Layouts.Msg
import Evergreen.V9.Main.Pages.Model
import Evergreen.V9.Main.Pages.Msg
import Evergreen.V9.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V9.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V9.Main.Layouts.Model.Model
    , shared : Evergreen.V9.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V9.Main.Pages.Msg.Msg
    | Layout Evergreen.V9.Main.Layouts.Msg.Msg
    | Shared Evergreen.V9.Shared.Msg
    | Batch (List Msg)
