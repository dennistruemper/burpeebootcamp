module Sound exposing (Sound(..), toString)

{-| Sound types for audio feedback in the app.
-}


type Sound
    = RepComplete
    | GroundTouch
    | WorkoutComplete
    | TimerWarning


{-| Convert a Sound to its filename string.
-}
toString : Sound -> String
toString sound =
    case sound of
        RepComplete ->
            "rep-complete.mp3"

        GroundTouch ->
            "ground-touch.mp3"

        WorkoutComplete ->
            "workout-complete.mp3"

        TimerWarning ->
            "timer-warning.mp3"
