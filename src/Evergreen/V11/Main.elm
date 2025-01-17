module Evergreen.V11.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V11.Main.Layouts.Model
import Evergreen.V11.Main.Layouts.Msg
import Evergreen.V11.Main.Pages.Model
import Evergreen.V11.Main.Pages.Msg
import Evergreen.V11.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V11.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V11.Main.Layouts.Model.Model
    , shared : Evergreen.V11.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V11.Main.Pages.Msg.Msg
    | Layout Evergreen.V11.Main.Layouts.Msg.Msg
    | Shared Evergreen.V11.Shared.Msg
    | Batch (List Msg)
