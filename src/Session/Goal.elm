module Session.Goal exposing
    ( GoalCalculationData
    , calculateNextGoal
    , calculateWorkoutGoal
    )

import Random
import Time exposing (Posix)
import WorkoutResult exposing (WorkoutResult)


type alias GoalCalculationData =
    { lastSessions : List WorkoutResult
    , currentTime : Posix
    , timeZone : Time.Zone
    }


calculateWorkoutGoal : GoalCalculationData -> Maybe Int -> Random.Generator Int
calculateWorkoutGoal history overwriteRepGoal =
    let
        dailyGoal : Int
        dailyGoal =
            calculateNextGoal history overwriteRepGoal
    in
    Random.int
        (min 200 (dailyGoal * 2))
        (min 200 (dailyGoal * 4))


calculateNextGoal : GoalCalculationData -> Maybe Int -> Int
calculateNextGoal history overwriteRepGoal =
    case overwriteRepGoal of
        Just repGoal ->
            Basics.max 10 repGoal

        Nothing ->
            let
                lastWorkout : Maybe WorkoutResult
                lastWorkout =
                    history.lastSessions
                        |> List.sortBy (\workout -> workout.timestamp |> Time.posixToMillis)
                        |> List.reverse
                        |> List.head

                daysSinceLastWorkout : Int
                daysSinceLastWorkout =
                    case lastWorkout of
                        Just workout ->
                            daysBetween history.timeZone workout.timestamp history.currentTime

                        Nothing ->
                            999

                adjustedGoal : Int
                adjustedGoal =
                    if daysSinceLastWorkout <= 1 then
                        -- Yesterday's or today's workout
                        case lastWorkout of
                            Just lw ->
                                let
                                    wasGoalReached : Bool
                                    wasGoalReached =
                                        Maybe.map2 (\goal reps -> reps >= goal) lw.repGoal (Just lw.reps)
                                            |> Maybe.withDefault False
                                in
                                if wasGoalReached then
                                    (lw.repGoal |> Maybe.withDefault 10) + 1

                                else
                                    lw.repGoal |> Maybe.withDefault 10

                            Nothing ->
                                10

                    else
                        -- Missed days: more aggressive reduction
                        case lastWorkout of
                            Just lw ->
                                let
                                    baseGoal : Int
                                    baseGoal =
                                        lw.repGoal |> Maybe.withDefault 10

                                    reduction : Int
                                    reduction =
                                        if daysSinceLastWorkout <= 7 then
                                            -- First week: 2 per day
                                            2 * (daysSinceLastWorkout - 1)

                                        else
                                            -- After a week: more aggressive reduction
                                            14 + (5 * (daysSinceLastWorkout - 7))
                                in
                                baseGoal - reduction

                            Nothing ->
                                10
            in
            Basics.max 10 adjustedGoal


getUpcomingMidnight : Time.Zone -> Posix -> Posix
getUpcomingMidnight zone t =
    let
        hourMillis : Int
        hourMillis =
            Time.toHour zone t * 60 * 60 * 1000

        minuteMillis : Int
        minuteMillis =
            Time.toMinute zone t * 60 * 1000

        secondMillis : Int
        secondMillis =
            Time.toSecond zone t * 1000
    in
    Time.posixToMillis t
        |> (\millis -> millis - hourMillis - minuteMillis - secondMillis + millisPerDay)
        |> Time.millisToPosix


millisPerDay : Int
millisPerDay =
    24 * 60 * 60 * 1000


daysBetween : Time.Zone -> Posix -> Posix -> Int
daysBetween zone t1 t2 =
    let
        midnight1 : Int
        midnight1 =
            getUpcomingMidnight zone t1
                |> Time.posixToMillis

        midnight2 : Int
        midnight2 =
            getUpcomingMidnight zone t2
                |> Time.posixToMillis
    in
    abs (midnight2 - midnight1) // millisPerDay
