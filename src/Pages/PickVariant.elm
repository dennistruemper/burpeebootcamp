module Pages.PickVariant exposing (Model, Msg(..), page)

import Burpee
import Dict
import Effect exposing (Effect)
import Html exposing (Html, button, div, h1, h2, input, p, text)
import Html.Attributes exposing (class, disabled, type_, value)
import Html.Events exposing (onClick, onInput)
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
    { variants : List Burpee.Burpee
    , selectedVariant : Maybe Burpee.Burpee
    , goalInput : String
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { variants = Burpee.variations
      , selectedVariant = Nothing
      , goalInput = ""
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = PickedVariant Burpee.Burpee
    | UpdateGoalInput String
    | StartWorkout
    | NavigateBack
    | BackToSelection


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        PickedVariant burpee ->
            ( { model | selectedVariant = Just burpee }
            , Effect.none
            )

        UpdateGoalInput input ->
            ( { model | goalInput = input }
            , Effect.none
            )

        StartWorkout ->
            ( model
            , Effect.batch
                [ Effect.newCurrentBurpee (Maybe.withDefault Burpee.default model.selectedVariant)
                , Effect.storeBurpeeVariant (Maybe.withDefault Burpee.default model.selectedVariant)
                , Effect.pushRoute { path = Route.Path.Counter, query = Dict.fromList [ ( "repGoal", model.goalInput ) ], hash = Nothing }
                ]
            )

        NavigateBack ->
            ( model
            , Effect.pushRoutePath Route.Path.Menu
            )

        BackToSelection ->
            ( { model | selectedVariant = Nothing, goalInput = "" }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Adjust Training Plan"
    , body =
        [ div [ class "p-4" ]
            [ h1 [ class "text-2xl mb-4" ] [ text "Adjust Training Plan" ]
            , case model.selectedVariant of
                Nothing ->
                    div [ class "mb-6" ]
                        [ h2 [ class "text-xl mb-2" ] [ text "Choose Burpee Variant" ]
                        , viewVariantList model.variants model.selectedVariant
                        ]

                Just selectedBurpee ->
                    div [ class "mb-6" ]
                        [ h2 [ class "text-xl mb-2" ] [ text <| "Set Goal for " ++ Burpee.getDisplayName selectedBurpee ]
                        , div [ class "mb-4" ]
                            [ input
                                [ type_ "number"
                                , class "w-24 p-2 border rounded"
                                , value model.goalInput
                                , onInput UpdateGoalInput
                                , Html.Attributes.min "10"
                                ]
                                []
                            ]
                        , div [ class "flex gap-4" ]
                            [ button
                                [ class """
                                    px-4 py-2 rounded
                                    disabled:opacity-50 disabled:cursor-not-allowed
                                    enabled:bg-amber-600 enabled:text-white enabled:hover:bg-amber-700
                                    disabled:bg-gray-300 disabled:text-gray-500
                                  """
                                , onClick StartWorkout
                                , disabled (String.isEmpty model.goalInput)
                                ]
                                [ text "Start Workout" ]
                            , button
                                [ class "px-4 py-2 border rounded"
                                , onClick BackToSelection
                                ]
                                [ text "Back to Selection" ]
                            , button
                                [ class "px-4 py-2 border rounded"
                                , onClick NavigateBack
                                ]
                                [ text "Cancel" ]
                            ]
                        ]
            ]
        ]
    }


viewVariantList : List Burpee.Burpee -> Maybe Burpee.Burpee -> Html.Html Msg
viewVariantList variants selectedVariant =
    Html.div
        [ class "max-w-3xl mx-auto grid gap-4 grid-cols-1 md:grid-cols-2" ]
        (List.map viewVariant variants)


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
