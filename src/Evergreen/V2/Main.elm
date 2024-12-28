module Evergreen.V2.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V2.Main.Layouts.Model
import Evergreen.V2.Main.Layouts.Msg
import Evergreen.V2.Main.Pages.Model
import Evergreen.V2.Main.Pages.Msg
import Evergreen.V2.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V2.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V2.Main.Layouts.Model.Model
    , shared : Evergreen.V2.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V2.Main.Pages.Msg.Msg
    | Layout Evergreen.V2.Main.Layouts.Msg.Msg
    | Shared Evergreen.V2.Shared.Msg
    | Batch (List Msg)
