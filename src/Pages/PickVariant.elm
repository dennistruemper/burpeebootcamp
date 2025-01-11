module Pages.PickVariant exposing (Model, Msg(..), page)

import Burpee
import Effect exposing (Effect)
import Html
import Html.Attributes exposing (class)
import Html.Events
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import Shared.Msg
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { variants : List Burpee.Burpee }


init : () -> ( Model, Effect Msg )
init () =
    ( { variants = Burpee.variations }
    , Effect.none
    )



-- UPDATE


type Msg
    = PickedVariant Burpee.Burpee


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        PickedVariant burpee ->
            ( model
            , Effect.batch
                [ Effect.newCurrentBurpee burpee
                , Effect.storeBurpeeVariant burpee
                , Effect.pushRoutePath Route.Path.Counter
                ]
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Pick Your Burpee Variant"
    , body =
        [ Html.div [ class "min-h-screen bg-gray-100 py-8 px-4" ]
            [ Html.h1
                [ class "text-3xl font-bold text-center text-gray-800 mb-8" ]
                [ Html.text "Choose your burpee variant" ]
            , Html.div
                [ class "max-w-3xl mx-auto grid gap-4 grid-cols-1 md:grid-cols-2" ]
                (List.map viewVariant model.variants)
            ]
        ]
    }


viewVariant : Burpee.Burpee -> Html.Html Msg
viewVariant burpee =
    Html.button
        [ Html.Events.onClick (PickedVariant burpee)
        , class """
            w-full p-4 bg-white rounded-lg shadow-md hover:shadow-lg
            transition-shadow duration-200 border border-gray-200
            text-left
          """
        ]
        [ Html.div []
            [ Html.h3
                [ class "text-xl font-semibold text-gray-800 mb-2" ]
                [ Html.text (Burpee.getDisplayName burpee) ]
            , Html.p
                [ class "text-gray-600 mb-2" ]
                [ Html.text (Burpee.toDescriptionString burpee) ]
            ]
        ]
