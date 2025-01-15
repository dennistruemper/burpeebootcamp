module Burpee exposing
    ( Burpee(..)
    , GroundAngle(..)
    , GroundPart(..)
    , TopPart(..)
    , calculateDifficulty
    , decodeJson
    , default
    , encodeJson
    , getDisplayName
    , toDescriptionString
    , variations
    )

import Json.Decode
import Json.Encode


type GroundAngle
    = HipInclined
    | KneeInclined
    | LittleInclined
    | Flat
    | LittleDecline
    | KneeDecline


type GroundPart
    = Plank
    | MountainClimbers Int
    | Pushups Int
    | NavySeals Int


type TopPart
    = Jump
    | TuckJump
    | KneeRaise
    | JumpingJack
    | BoxJump
    | PullUp
    | NoOp


getDifficultyForGroundAngle : GroundAngle -> Float
getDifficultyForGroundAngle angle =
    case angle of
        HipInclined ->
            1

        KneeInclined ->
            1.2

        LittleInclined ->
            1.6

        Flat ->
            2

        LittleDecline ->
            2.5

        KneeDecline ->
            3


getDifficultyForGroundPart : GroundPart -> Float
getDifficultyForGroundPart part =
    case part of
        Plank ->
            1

        MountainClimbers n ->
            toFloat n * 1.2

        Pushups n ->
            toFloat n * 1.5

        NavySeals n ->
            toFloat n * 2


getDifficultyForTopPart : TopPart -> Float
getDifficultyForTopPart part =
    case part of
        NoOp ->
            1

        KneeRaise ->
            1.2

        Jump ->
            1.5

        JumpingJack ->
            1.7

        TuckJump ->
            1.8

        BoxJump ->
            2

        PullUp ->
            3



-- gentle burpee | plank, one leg ofter the other | nothing on top
-- half burpee | plank | nothing on top
-- 1 pump | 1 pushup | nothing on top
-- og burpee (rocky chair) | andre transition
-- 8 count bodybuilder | 1 pushup, open close legs in plank
-- 2 pump | 2 pushup | nothing on top
-- army ranger | 2 pushup, kickout in between, jump feet forward and back again
-- 3 pump | 3 pushup | nothing on top
-- navy seals | 3 pushup, one leg raise during the first two pushups
-- 5 pump navy seals | 5 pushup, one leg raise during the first four pushups


type Burpee
    = Burpee { name : String, angle : GroundAngle, groundPart : GroundPart, topPart : TopPart }


default : Burpee
default =
    Burpee { name = "Basic Burpee", angle = Flat, groundPart = Pushups 1, topPart = NoOp }


variations : List Burpee
variations =
    [ Burpee { name = "Half Burpee (Chair)", angle = KneeInclined, groundPart = Plank, topPart = NoOp }
    , Burpee { name = "1 Pump (Chair)", angle = KneeInclined, groundPart = Pushups 1, topPart = NoOp }
    , Burpee { name = "Gentle Burpee (Parallets)", angle = LittleInclined, groundPart = Plank, topPart = KneeRaise }
    , Burpee { name = "Half Burpee (Parallets)", angle = LittleInclined, groundPart = MountainClimbers 1, topPart = KneeRaise }
    , Burpee { name = "1 Pump (Parallets)", angle = LittleInclined, groundPart = Pushups 1, topPart = KneeRaise }
    , Burpee { name = "1 Pump", angle = Flat, groundPart = Pushups 2, topPart = KneeRaise }
    , Burpee { name = "2 Pump", angle = Flat, groundPart = Pushups 2, topPart = KneeRaise }
    , Burpee { name = "2 Pump JJ", angle = Flat, groundPart = Pushups 2, topPart = JumpingJack }
    , Burpee { name = "3 Pump", angle = Flat, groundPart = Pushups 3, topPart = KneeRaise }
    , Burpee { name = "3 Pump Navy Seals", angle = Flat, groundPart = NavySeals 3, topPart = KneeRaise }
    , Burpee { name = "5 Pump Navy Seals", angle = Flat, groundPart = NavySeals 5, topPart = KneeRaise }
    ]
        |> sortByDifficulty


sortByDifficulty : List Burpee -> List Burpee
sortByDifficulty burpees =
    List.sortBy calculateDifficulty burpees


getDisplayName : Burpee -> String
getDisplayName burpee =
    case burpee of
        Burpee data ->
            data.name


angleToString : GroundAngle -> String
angleToString angle =
    case angle of
        HipInclined ->
            "Hip high inclined"

        KneeInclined ->
            "Knee high inclined"

        LittleInclined ->
            "Slightly inclined"

        Flat ->
            "Flat"

        LittleDecline ->
            "Slightly declined"

        KneeDecline ->
            "Knee high declined"


groundPartToString : GroundPart -> String
groundPartToString part =
    case part of
        Plank ->
            "Plank"

        MountainClimbers n ->
            String.fromInt n ++ " Mountain Climbers"

        Pushups n ->
            String.fromInt n ++ " Pushups"

        NavySeals n ->
            String.fromInt n ++ " Navy Seals (one leg raise during each pushup, except the last one)"


topPartToString : TopPart -> String
topPartToString part =
    case part of
        Jump ->
            "Jump"

        KneeRaise ->
            "Knee Raise"

        TuckJump ->
            "Tuck Jump"

        JumpingJack ->
            "Jumping Jack"

        BoxJump ->
            "Box Jump"

        PullUp ->
            "Pull Up"

        NoOp ->
            ""


calculateDifficulty : Burpee -> Int
calculateDifficulty burpee =
    case burpee of
        Burpee data ->
            -- times 10 to leave "space" for user defined variations
            round (10 * (getDifficultyForGroundAngle data.angle * getDifficultyForGroundPart data.groundPart * getDifficultyForTopPart data.topPart))


toDescriptionString : Burpee -> String
toDescriptionString burpee =
    case burpee of
        Burpee data ->
            angleToString data.angle ++ " " ++ groundPartToString data.groundPart ++ " " ++ topPartToString data.topPart



-- CODECS


decodeJson : Json.Decode.Decoder Burpee
decodeJson =
    Json.Decode.field "tag" Json.Decode.string
        |> Json.Decode.andThen
            (\ctor ->
                case ctor of
                    "Burpee" ->
                        Json.Decode.map
                            Burpee
                            (Json.Decode.field
                                "data"
                                (Json.Decode.map4
                                    (\name angle groundPart topPart ->
                                        { name = name, angle = angle, groundPart = groundPart, topPart = topPart }
                                    )
                                    (Json.Decode.field "name" Json.Decode.string)
                                    (Json.Decode.field "angle" decodeGroundAngle)
                                    (Json.Decode.field "groundPart" decodeGroundPart)
                                    (Json.Decode.field "topPart" decodeTopPart)
                                )
                            )

                    _ ->
                        Json.Decode.fail "Unrecognized constructor"
            )


encodeJson : Burpee -> Json.Encode.Value
encodeJson burpee =
    case burpee of
        Burpee arg0 ->
            Json.Encode.object
                [ ( "tag", Json.Encode.string "Burpee" )
                , ( "data"
                  , Json.Encode.object
                        [ ( "name", Json.Encode.string arg0.name )
                        , ( "angle", encodeGroundAngle arg0.angle )
                        , ( "groundPart", encodeGroundPart arg0.groundPart )
                        , ( "topPart", encodeTopPart arg0.topPart )
                        ]
                  )
                ]


encodeGroundAngle : GroundAngle -> Json.Encode.Value
encodeGroundAngle arg =
    case arg of
        HipInclined ->
            Json.Encode.string "HipInclined"

        KneeInclined ->
            Json.Encode.string "KneeInclined"

        LittleInclined ->
            Json.Encode.string "LittleInclined"

        Flat ->
            Json.Encode.string "Flat"

        LittleDecline ->
            Json.Encode.string "LittleDecline"

        KneeDecline ->
            Json.Encode.string "KneeDecline"


encodeGroundPart : GroundPart -> Json.Encode.Value
encodeGroundPart arg =
    case arg of
        Plank ->
            Json.Encode.object [ ( "tag", Json.Encode.string "Plank" ) ]

        MountainClimbers arg0 ->
            Json.Encode.object [ ( "tag", Json.Encode.string "MountainClimbers" ), ( "0", Json.Encode.int arg0 ) ]

        Pushups arg0 ->
            Json.Encode.object [ ( "tag", Json.Encode.string "Pushups" ), ( "0", Json.Encode.int arg0 ) ]

        NavySeals arg0 ->
            Json.Encode.object [ ( "tag", Json.Encode.string "NavySeals" ), ( "0", Json.Encode.int arg0 ) ]


encodeTopPart : TopPart -> Json.Encode.Value
encodeTopPart arg =
    case arg of
        Jump ->
            Json.Encode.string "Jump"

        TuckJump ->
            Json.Encode.string "TuckJump"

        KneeRaise ->
            Json.Encode.string "KneeRaise"

        JumpingJack ->
            Json.Encode.string "JumpingJack"

        BoxJump ->
            Json.Encode.string "BoxJump"

        PullUp ->
            Json.Encode.string "PullUp"

        NoOp ->
            Json.Encode.string "NoOp"


decodeGroundAngle : Json.Decode.Decoder GroundAngle
decodeGroundAngle =
    Json.Decode.string
        |> Json.Decode.andThen
            (\str ->
                case str of
                    "HipInclined" ->
                        Json.Decode.succeed HipInclined

                    "KneeInclined" ->
                        Json.Decode.succeed KneeInclined

                    "LittleInclined" ->
                        Json.Decode.succeed LittleInclined

                    "Flat" ->
                        Json.Decode.succeed Flat

                    "LittleDecline" ->
                        Json.Decode.succeed LittleDecline

                    "KneeDecline" ->
                        Json.Decode.succeed KneeDecline

                    _ ->
                        Json.Decode.fail "Invalid ground angle"
            )


decodeGroundPart : Json.Decode.Decoder GroundPart
decodeGroundPart =
    Json.Decode.field "tag" Json.Decode.string
        |> Json.Decode.andThen
            (\ctor ->
                case ctor of
                    "Plank" ->
                        Json.Decode.succeed Plank

                    "MountainClimbers" ->
                        Json.Decode.map MountainClimbers (Json.Decode.field "0" Json.Decode.int)

                    "Pushups" ->
                        Json.Decode.map Pushups (Json.Decode.field "0" Json.Decode.int)

                    "NavySeals" ->
                        Json.Decode.map NavySeals (Json.Decode.field "0" Json.Decode.int)

                    _ ->
                        Json.Decode.fail "Unrecognized constructor"
            )


decodeTopPart : Json.Decode.Decoder TopPart
decodeTopPart =
    Json.Decode.string
        |> Json.Decode.andThen
            (\str ->
                case str of
                    "Jump" ->
                        Json.Decode.succeed Jump

                    "TuckJump" ->
                        Json.Decode.succeed TuckJump

                    "KneeRaise" ->
                        Json.Decode.succeed KneeRaise

                    "JumpingJack" ->
                        Json.Decode.succeed JumpingJack

                    "BoxJump" ->
                        Json.Decode.succeed BoxJump

                    "PullUp" ->
                        Json.Decode.succeed PullUp

                    "NoOp" ->
                        Json.Decode.succeed NoOp

                    _ ->
                        Json.Decode.fail "Invalid top part"
            )
