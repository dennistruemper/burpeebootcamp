module Evergreen.V8.Burpee exposing (..)


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


type Burpee
    = Burpee
        { name : String
        , angle : GroundAngle
        , groundPart : GroundPart
        , topPart : TopPart
        }
