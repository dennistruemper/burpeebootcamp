module Evergreen.V12.Main exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V12.Main.Layouts.Model
import Evergreen.V12.Main.Layouts.Msg
import Evergreen.V12.Main.Pages.Model
import Evergreen.V12.Main.Pages.Msg
import Evergreen.V12.Shared
import Url


type alias Model =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , page : Evergreen.V12.Main.Pages.Model.Model
    , layout : Maybe Evergreen.V12.Main.Layouts.Model.Model
    , shared : Evergreen.V12.Shared.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | Page Evergreen.V12.Main.Pages.Msg.Msg
    | Layout Evergreen.V12.Main.Layouts.Msg.Msg
    | Shared Evergreen.V12.Shared.Msg
    | Batch (List Msg)
