module Evergreen.V2.Burpee exposing (..)

import Time


type PlacementOption
    = Standard
    | HandsInclined
    | FeetInclined
    | HandsOnParallettes
    | HandsOnRings


type BottomPosition
    = KneePushup
    | RegularPushup
    | DoublePushup
    | ArcherPushup
    | NavySeal


type TopPosition
    = StepUp
    | AlternatingKneeRaise
    | Jump
    | Squat
    | JumpSquat


type alias BurpeeConfig =
    { placement : PlacementOption
    , bottom : BottomPosition
    , top : TopPosition
    }


type alias WorkoutStats =
    { reps : Int
    , timePerRep : Float
    , date : Time.Posix
    }
