module Route.Path exposing (Path(..), fromString, fromUrl, href, toString)

import Html
import Html.Attributes
import Url exposing (Url)
import Url.Parser exposing ((</>))


type Path
    = Home_
    | Counter
    | Menu
    | PickVariant
    | Results
    | NotFound_


fromUrl : Url -> Path
fromUrl url =
    fromString url.path
        |> Maybe.withDefault NotFound_


fromString : String -> Maybe Path
fromString urlPath =
    let
        urlPathSegments : List String
        urlPathSegments =
            urlPath
                |> String.split "/"
                |> List.filter (String.trim >> String.isEmpty >> Basics.not)
    in
    case urlPathSegments of
        [] ->
            Just Home_

        "counter" :: [] ->
            Just Counter

        "menu" :: [] ->
            Just Menu

        "pick-variant" :: [] ->
            Just PickVariant

        "results" :: [] ->
            Just Results

        _ ->
            Nothing


href : Path -> Html.Attribute msg
href path =
    Html.Attributes.href (toString path)


toString : Path -> String
toString path =
    let
        pieces : List String
        pieces =
            case path of
                Home_ ->
                    []

                Counter ->
                    [ "counter" ]

                Menu ->
                    [ "menu" ]

                PickVariant ->
                    [ "pick-variant" ]

                Results ->
                    [ "results" ]

                NotFound_ ->
                    [ "404" ]
    in
    pieces
        |> String.join "/"
        |> String.append "/"
