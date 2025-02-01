module Session.GoalTest exposing (suite)

import Burpee exposing (Burpee)
import Expect
import Session.Goal
import Test exposing (Test, describe, test)
import Time


suite : Test
suite =
    describe "Session.Goal"
        [ describe "calculateNextGoal"
            [ test "successful session increases goal by 1" <|
                \_ ->
                    let
                        history : Session.Goal.GoalCalculationData
                        history =
                            { lastSessions =
                                [ { reps = 15
                                  , repGoal = Just 15
                                  , timestamp = Time.millisToPosix (dayOffset -1)
                                  , burpee = defaultBurpee
                                  , sessionType = Nothing
                                  }
                                ]
                            , currentTime = Time.millisToPosix 0
                            , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                            }
                    in
                    Session.Goal.calculateNextGoal history Nothing
                        |> Expect.equal 16
            , test "failed session keeps same goal" <|
                \_ ->
                    let
                        history : Session.Goal.GoalCalculationData
                        history =
                            { lastSessions =
                                [ { reps = 14
                                  , repGoal = Just 15
                                  , timestamp = Time.millisToPosix (dayOffset -1)
                                  , burpee = defaultBurpee
                                  , sessionType = Nothing
                                  }
                                ]
                            , currentTime = Time.millisToPosix 0
                            , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                            }
                    in
                    Session.Goal.calculateNextGoal history Nothing
                        |> Expect.equal 15
            , describe "missed days"
                [ test "1 missed day reduces goal by 2" <|
                    \_ ->
                        let
                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 20
                                      , repGoal = Just 20
                                      , timestamp = Time.millisToPosix (dayOffset -2)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = Time.millisToPosix 0
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 18
                , test "2 missed days reduces goal by 4" <|
                    \_ ->
                        let
                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 20
                                      , repGoal = Just 20
                                      , timestamp = Time.millisToPosix (dayOffset -3)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = Time.millisToPosix 0
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 16
                , test "goal never goes below 10" <|
                    \_ ->
                        let
                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 12
                                      , repGoal = Just 12
                                      , timestamp = Time.millisToPosix (dayOffset -5)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = Time.millisToPosix 0
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 10
                ]
            , test "overwrite goal takes precedence" <|
                \_ ->
                    let
                        history : Session.Goal.GoalCalculationData
                        history =
                            { lastSessions =
                                [ { reps = 15
                                  , repGoal = Just 15
                                  , timestamp = Time.millisToPosix (dayOffset -1)
                                  , burpee = defaultBurpee
                                  , sessionType = Nothing
                                  }
                                ]
                            , currentTime = Time.millisToPosix 0
                            , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                            }
                    in
                    Session.Goal.calculateNextGoal history (Just 25)
                        |> Expect.equal 25
            , test "no previous sessions starts with 10" <|
                \_ ->
                    let
                        history : Session.Goal.GoalCalculationData
                        history =
                            { lastSessions = []
                            , currentTime = Time.millisToPosix 0
                            , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                            }
                    in
                    Session.Goal.calculateNextGoal history Nothing
                        |> Expect.equal 10
            , describe "day boundary edge cases"
                [ test "same calendar day counts as same day" <|
                    \_ ->
                        let
                            sessionTime : Time.Posix
                            sessionTime =
                                Time.millisToPosix 1704110400000

                            currentTime : Time.Posix
                            currentTime =
                                Time.millisToPosix 1704157140000

                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 15
                                      , repGoal = Just 15
                                      , timestamp = sessionTime
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = currentTime
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 16
                , test "next calendar day at 1am counts as consecutive day" <|
                    \_ ->
                        let
                            sessionTime : Time.Posix
                            sessionTime =
                                Time.millisToPosix 1704110400000

                            currentTime : Time.Posix
                            currentTime =
                                Time.millisToPosix 1704164400000

                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 15
                                      , repGoal = Just 15
                                      , timestamp = sessionTime
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = currentTime
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 16
                , test "skipping a calendar day counts as missed day" <|
                    \_ ->
                        let
                            sessionTime : Time.Posix
                            sessionTime =
                                Time.millisToPosix 1704110400000

                            currentTime : Time.Posix
                            currentTime =
                                Time.millisToPosix 1704250800000

                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 15
                                      , repGoal = Just 15
                                      , timestamp = sessionTime
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = currentTime
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 13
                , test "late night followed by early morning counts as consecutive days" <|
                    \_ ->
                        let
                            sessionTime : Time.Posix
                            sessionTime =
                                Time.millisToPosix 1704155400000

                            currentTime : Time.Posix
                            currentTime =
                                Time.millisToPosix 1704176400000

                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 15
                                      , repGoal = Just 15
                                      , timestamp = sessionTime
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = currentTime
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 16
                , test "timezone boundary does not affect day calculation" <|
                    \_ ->
                        let
                            sessionTime : Time.Posix
                            sessionTime =
                                Time.millisToPosix 1704155400000

                            currentTime : Time.Posix
                            currentTime =
                                Time.millisToPosix 1704159000000

                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 15
                                      , repGoal = Just 15
                                      , timestamp = sessionTime
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = currentTime
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 16
                ]
            , describe "multiple sessions in history"
                [ test "uses most recent session for calculation" <|
                    \_ ->
                        let
                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 15
                                      , repGoal = Just 15
                                      , timestamp = Time.millisToPosix (dayOffset -1)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    , { reps = 20
                                      , repGoal = Just 20
                                      , timestamp = Time.millisToPosix (dayOffset -2)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = Time.millisToPosix 0
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 16
                , test "ignores older failed sessions if recent one succeeded" <|
                    \_ ->
                        let
                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 15
                                      , repGoal = Just 15
                                      , timestamp = Time.millisToPosix (dayOffset -1)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    , { reps = 12
                                      , repGoal = Just 15
                                      , timestamp = Time.millisToPosix (dayOffset -2)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = Time.millisToPosix 0
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 16
                ]
            , describe "very large gaps between sessions"
                [ test "30 days without session reduces to minimum" <|
                    \_ ->
                        let
                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 100
                                      , repGoal = Just 100
                                      , timestamp = Time.millisToPosix (dayOffset -30)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = Time.millisToPosix 0
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 10
                , test "maintains minimum of 10 even after 100 days" <|
                    \_ ->
                        let
                            history : Session.Goal.GoalCalculationData
                            history =
                                { lastSessions =
                                    [ { reps = 50
                                      , repGoal = Just 50
                                      , timestamp = Time.millisToPosix (dayOffset -100)
                                      , burpee = defaultBurpee
                                      , sessionType = Nothing
                                      }
                                    ]
                                , currentTime = Time.millisToPosix 0
                                , timeZone = Time.customZone (10 * 60) [] -- Australia/Sydney (+10:00)
                                }
                        in
                        Session.Goal.calculateNextGoal history Nothing
                            |> Expect.equal 10
                ]
            ]
        ]



-- Helper functions


dayOffset : Int -> Int
dayOffset days =
    days * 24 * 60 * 60 * 1000


defaultBurpee : Burpee
defaultBurpee =
    Burpee.default
