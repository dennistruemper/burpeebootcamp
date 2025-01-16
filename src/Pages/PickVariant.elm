module Pages.PickVariant exposing (Model, Msg(..), page)

import Burpee
import Dict
import Effect exposing (Effect)
import Html exposing (button, div, h1, h2, input, p, text)
import Html.Attributes exposing (class, disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init route
        , update = update
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    { variants : List Burpee.Burpee
    , selectedVariant : Maybe Burpee.Burpee
    , goalInput : String
    , first : Bool
    }


init : Route () -> () -> ( Model, Effect Msg )
init route () =
    ( { variants = Burpee.variations
      , selectedVariant = Nothing
      , goalInput = ""
      , first = Dict.get "first" route.query |> Maybe.map (\first -> first == "true") |> Maybe.withDefault False
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
            if model.first then
                ( model
                , Effect.batch
                    [ Effect.newCurrentBurpee burpee
                    , Effect.storeBurpeeVariant burpee
                    , Effect.pushRoute { path = Route.Path.Counter, query = Dict.fromList [ ( "repGoal", "10" ) ], hash = Nothing }
                    ]
                )

            else
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
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Adjust Training Plan"
    , body =
        [ div [ class "p-4" ]
            [ h1 [ class "text-2xl mb-4" ] [ text "Adjust Training Plan" ]
            , case model.selectedVariant of
                Nothing ->
                    div [ class "mb-6" ]
                        [ div [ class "mb-8 max-w-3xl mx-auto" ]
                            [ p [ class "text-lg text-amber-900 mb-4" ]
                                [ text "Choose your starting point wisely! The key to mastering burpees is progressive overload - we'll work our way up to 100 repetitions together. 💪" ]
                            , div [ class "bg-amber-50 border-l-4 border-amber-600 p-4" ]
                                [ p [ class "text-amber-800 mb-2" ]
                                    [ text "Pro tip: Pick a variation where you can easily do 10 repetitions with good form. This isn't about pushing to your limits today - it's about building a strong foundation for tomorrow." ]
                                , p [ class "text-amber-700" ]
                                    [ text "Remember: The best progression is the one you can stick with. Start easy, stay consistent, and watch yourself grow stronger day by day! 🌱 → 🌳" ]
                                ]
                            ]
                        , h2 [ class "text-xl mb-2" ] [ text "Choose Burpee Variant" ]
                        , viewVariantList model.variants shared.currentBurpee
                        ]

                Just selectedBurpee ->
                    if model.first then
                        div [] []

                    else
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
viewVariantList variants currentBurpee =
    let
        sortedVariants : List Burpee.Burpee
        sortedVariants =
            variants
                |> List.sortBy Burpee.calculateDifficulty

        ( easyVariants, remainingVariants ) =
            List.partition (\b -> Burpee.calculateDifficulty b <= 25) sortedVariants

        ( mediumVariants, hardAndVeryHard ) =
            List.partition (\b -> Burpee.calculateDifficulty b <= 73) remainingVariants

        ( hardVariants, veryHardVariants ) =
            List.partition (\b -> Burpee.calculateDifficulty b <= 130) hardAndVeryHard

        sectionHeader : String -> Html.Html Msg
        sectionHeader text =
            Html.h2
                [ class "col-span-1 md:col-span-2 text-xl font-semibold text-amber-800 mt-6 first:mt-0" ]
                [ Html.text text ]

        variantSection : String -> List Burpee.Burpee -> List (Html.Html Msg)
        variantSection headerText variants_ =
            if List.isEmpty variants_ then
                []

            else
                sectionHeader headerText :: List.map (viewVariant currentBurpee) variants_
    in
    Html.div
        [ class "max-w-3xl mx-auto grid gap-4 grid-cols-1 md:grid-cols-2" ]
        (List.concat
            [ variantSection "Beginner Friendly 🌱" easyVariants
            , variantSection "Intermediate 💪" mediumVariants
            , variantSection "Advanced 🔥" hardVariants
            , variantSection "Expert 🌳" veryHardVariants
            ]
        )


viewVariant : Maybe Burpee.Burpee -> Burpee.Burpee -> Html.Html Msg
viewVariant selectedVariant burpee =
    Html.button
        [ Html.Events.onClick (PickedVariant burpee)
        , class """
            w-full p-4 rounded-lg shadow-md hover:shadow-lg
            transition-shadow duration-200 border-2
            text-left
            relative
          """
        , class <|
            if selectedVariant == Just burpee then
                "bg-amber-50 border-amber-600"

            else
                "bg-white border-gray-200"
        ]
        [ Html.div []
            [ Html.h3
                [ class "text-xl font-semibold text-gray-800 mb-2" ]
                [ Html.text (Burpee.getDisplayName burpee) ]
            , Html.p
                [ class "text-gray-600 mb-2" ]
                [ Html.text (Burpee.toDescriptionString burpee) ]
            ]
        , if selectedVariant == Just burpee then
            Html.div
                [ class "absolute top-2 right-2" ]
                [ Html.text "✓" ]

          else
            Html.text ""
        ]
