module Pages.Results exposing (Model, Msg(..), page)

import Dict
import Effect exposing (Effect)
import Html exposing (Html, button, div, h1, h2, h3, input, span, text)
import Html.Attributes exposing (class, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import Time
import View exposing (View)
import WorkoutResult exposing (WorkoutResult)


page : Shared.Model -> Route () -> Page Model Msg
page shared _ =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    { currentTime : Time.Posix
    , selectedDate : Maybe Time.Posix
    , daysToShow : Int
    , popoverDay : Maybe Time.Posix
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { currentTime = Time.millisToPosix 0
      , selectedDate = Nothing
      , daysToShow = 40
      , popoverDay = Nothing
      }
    , Effect.getTime GotCurrentTime
    )



-- UPDATE


type Msg
    = GotCurrentTime Time.Posix
    | UpdateDaysToShow Int
    | NavigateToMenu
    | TogglePopover (Maybe Time.Posix)
    | NoOp
    | CloseSlider


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotCurrentTime time ->
            ( { model | currentTime = time }
            , Effect.none
            )

        UpdateDaysToShow days ->
            ( { model | daysToShow = days }
            , Effect.none
            )

        NavigateToMenu ->
            ( model
            , Effect.pushRoute
                { path = Route.Path.Menu
                , query = Dict.empty
                , hash = Nothing
                }
            )

        TogglePopover maybeDate ->
            ( { model | popoverDay = maybeDate }
            , Effect.none
            )

        NoOp ->
            ( model, Effect.none )

        CloseSlider ->
            ( { model | popoverDay = Nothing }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Practice History - BurpeeBootcamp"
    , body =
        if shared.initializing then
            [ text "Loading..." ]

        else
            [ div [ class "results-container p-4" ]
                [ div [ class "flex justify-between items-center mb-6" ]
                    [ h1 [ class "results-title text-2xl font-bold" ]
                        [ text "Your Practice Sessions" ]
                    , button
                        [ class "px-4 py-2 rounded-lg bg-amber-600 hover:bg-amber-700 text-white font-bold shadow-lg transform transition hover:scale-105"
                        , onClick NavigateToMenu
                        ]
                        [ text "Menu" ]
                    ]
                , viewCalendar shared.workoutHistory model
                ]
            ]
    }


viewCalendar : List WorkoutResult -> Model -> Html Msg
viewCalendar workouts model =
    let
        -- Helper to create a unique key for each month
        monthKey : Int -> Time.Month -> String
        monthKey year month =
            String.fromInt year ++ "-" ++ monthToString month

        -- Helper to group days by month
        groupByMonth : List Time.Posix -> List ( Time.Month, List { time : Time.Posix, isDummy : Bool } )
        groupByMonth dates =
            let
                insertDate : Time.Posix -> Dict.Dict String (List { time : Time.Posix, isDummy : Bool }) -> Dict.Dict String (List { time : Time.Posix, isDummy : Bool })
                insertDate date dict =
                    let
                        month : Time.Month
                        month =
                            Time.toMonth Time.utc date

                        year : Int
                        year =
                            Time.toYear Time.utc date

                        key : String
                        key =
                            monthKey year month
                    in
                    Dict.update key
                        (\maybeList ->
                            case maybeList of
                                Just list ->
                                    Just (list ++ [ { time = date, isDummy = False } ])

                                Nothing ->
                                    Just [ { time = date, isDummy = False } ]
                        )
                        dict

                -- Add padding days based on weekday of last day of month
                addPaddingDays : List { time : Time.Posix, isDummy : Bool } -> List { time : Time.Posix, isDummy : Bool }
                addPaddingDays dates_ =
                    case List.head (List.reverse dates_) of
                        Nothing ->
                            []

                        Just lastDate ->
                            let
                                weekday : Time.Weekday
                                weekday =
                                    Time.toWeekday Time.utc lastDate.time

                                paddingCount : Int
                                paddingCount =
                                    case weekday of
                                        Time.Mon ->
                                            6

                                        Time.Tue ->
                                            5

                                        Time.Wed ->
                                            4

                                        Time.Thu ->
                                            3

                                        Time.Fri ->
                                            2

                                        Time.Sat ->
                                            1

                                        Time.Sun ->
                                            0

                                -- Create dummy dates for padding
                                oneMonthInMillis : Int
                                oneMonthInMillis =
                                    1000 * 60 * 60 * 24 * 30

                                paddingDates : List { time : Time.Posix, isDummy : Bool }
                                paddingDates =
                                    List.range 1 paddingCount
                                        |> List.map (\_ -> { time = Time.millisToPosix (Time.posixToMillis lastDate.time + oneMonthInMillis), isDummy = True })
                            in
                            paddingDates ++ dates_

                -- Helper to get a sortable value for a month/year combination
            in
            dates
                |> List.foldl insertDate Dict.empty
                |> Dict.toList
                |> List.map
                    (\( _, dates_ ) ->
                        case List.head dates_ of
                            Just date ->
                                ( Time.toMonth Time.utc date.time
                                  -- Sort days in reverse chronological order
                                , dates_
                                    |> List.sortBy (\d -> Time.posixToMillis d.time)
                                    |> List.reverse
                                    |> addPaddingDays
                                )

                            Nothing ->
                                ( Time.Jan, dates_ )
                    )
                |> List.sortBy
                    (\( _, dates_ ) ->
                        -- Sort months in chronological order
                        case List.head dates_ of
                            Just date ->
                                -(Time.posixToMillis date.time)

                            -- Negative to get chronological order
                            Nothing ->
                                0
                    )

        -- Get the last 40 days, starting from today
        getDaysToShow : Time.Posix -> List Time.Posix
        getDaysToShow currentTime =
            List.range 0 (model.daysToShow - 1)
                |> List.map
                    (\dayOffset ->
                        Time.posixToMillis currentTime
                            - (dayOffset * 24 * 60 * 60 * 1000)
                            |> Time.millisToPosix
                    )

        -- Helper to get workout for a specific day
        getWorkout : Time.Posix -> Maybe DayStats
        getWorkout date =
            List.filter
                (\workout ->
                    let
                        workoutDay : Int
                        workoutDay =
                            Time.toDay Time.utc workout.timestamp

                        workoutMonth : Time.Month
                        workoutMonth =
                            Time.toMonth Time.utc workout.timestamp

                        workoutYear : Int
                        workoutYear =
                            Time.toYear Time.utc workout.timestamp

                        targetDay : Int
                        targetDay =
                            Time.toDay Time.utc date

                        targetMonth : Time.Month
                        targetMonth =
                            Time.toMonth Time.utc date

                        targetYear : Int
                        targetYear =
                            Time.toYear Time.utc date
                    in
                    workoutDay == targetDay && workoutMonth == targetMonth && workoutYear == targetYear
                )
                workouts
                |> (\workoutsForDay ->
                        case workoutsForDay of
                            [] ->
                                Nothing

                            firstWorkout :: _ ->
                                Just
                                    { totalReps = List.foldl (\w sum -> sum + w.reps) 0 workoutsForDay
                                    , sessionCount = List.length workoutsForDay
                                    , timestamp = firstWorkout.timestamp
                                    , sessions = List.sortBy (\w -> -(Time.posixToMillis w.timestamp)) workoutsForDay
                                    }
                   )

        visibleWorkouts : List DayStats
        visibleWorkouts =
            getDaysToShow model.currentTime
                |> List.filterMap getWorkout

        minReps : Int
        minReps =
            visibleWorkouts
                |> List.map .totalReps
                |> List.minimum
                |> Maybe.withDefault 0

        maxReps : Int
        maxReps =
            visibleWorkouts
                |> List.map .totalReps
                |> List.maximum
                |> Maybe.withDefault 0

        getColorClass : Int -> String
        getColorClass totalReps =
            if maxReps == minReps then
                "bg-amber-500"

            else
                let
                    percentage : Float
                    percentage =
                        toFloat (totalReps - minReps) / toFloat (maxReps - minReps)
                in
                if percentage <= 0.2 then
                    "bg-amber-100"

                else if percentage <= 0.4 then
                    "bg-amber-200"

                else if percentage <= 0.6 then
                    "bg-amber-300"

                else if percentage <= 0.8 then
                    "bg-amber-400"

                else
                    "bg-amber-500"

        -- Calculate max days possible to show
        maxDaysToShow : Int
        maxDaysToShow =
            case List.minimum (List.map (.timestamp >> Time.posixToMillis) workouts) of
                Just oldestTimestamp ->
                    let
                        daysDiff : Int
                        daysDiff =
                            (Time.posixToMillis model.currentTime - oldestTimestamp)
                                // (24 * 60 * 60 * 1000)
                    in
                    Basics.max 40 (daysDiff + 1) |> Basics.min 700

                Nothing ->
                    40

        -- Only show slider if we have more than 40 days of history
        showSlider : Bool
        showSlider =
            maxDaysToShow
                /= 40

        viewDay : Time.Posix -> Bool -> Html Msg
        viewDay date isDummy =
            if isDummy then
                -- Render empty padding cell
                div [ class "aspect-square" ]
                    [ div [ class "h-full flex items-center justify-center" ]
                        []
                    ]

            else
                -- Existing day rendering code
                let
                    workout : Maybe DayStats
                    workout =
                        getWorkout date

                    isToday : Bool
                    isToday =
                        Time.toDay Time.utc date
                            == Time.toDay Time.utc model.currentTime
                            && Time.toMonth Time.utc date
                            == Time.toMonth Time.utc model.currentTime
                            && Time.toYear Time.utc date
                            == Time.toYear Time.utc model.currentTime

                    baseClass : String
                    baseClass =
                        if isToday then
                            "aspect-square ring-2 ring-amber-500"

                        else
                            "aspect-square"
                in
                case workout of
                    Just w ->
                        div [ class (baseClass ++ " relative") ]
                            [ div
                                [ class (getColorClass w.totalReps ++ " h-full flex flex-col items-center justify-center cursor-pointer")
                                , onClick (TogglePopover (Just date))
                                ]
                                [ div [ class "text-sm font-semibold" ]
                                    [ text (String.fromInt (Time.toDay Time.utc date)) ]
                                , div [ class "text-xs" ]
                                    [ text ("(" ++ String.fromInt w.totalReps ++ ", " ++ String.fromInt w.sessionCount ++ ")") ]
                                ]
                            , if model.popoverDay |> Maybe.map (isSameDay date) |> Maybe.withDefault False then
                                viewPopover w

                              else
                                text ""
                            ]

                    Nothing ->
                        div [ class baseClass ]
                            [ div [ class "h-full flex items-center justify-center border border-gray-200" ]
                                [ div [ class "text-sm text-gray-400" ]
                                    [ text (String.fromInt (Time.toDay Time.utc date)) ]
                                ]
                            ]
    in
    div [ class "max-w-3xl mx-auto bg-white rounded-lg shadow relative" ]
        [ div [ class "px-4 py-3" ]
            [ div [ class "flex flex-col gap-2" ]
                [ h2 [ class "flex-auto text-sm font-semibold text-amber-900" ]
                    [ text ("Last " ++ String.fromInt model.daysToShow ++ " Days") ]
                , if showSlider then
                    div [ class "flex items-center gap-2 text-xs text-amber-800" ]
                        [ span [] [ text "40" ]
                        , input
                            [ type_ "range"
                            , Html.Attributes.min "40"
                            , Html.Attributes.max (String.fromInt maxDaysToShow)
                            , value (String.fromInt model.daysToShow)
                            , class "w-full h-1.5 bg-amber-200 rounded-lg appearance-none cursor-pointer accent-amber-600"
                            , onInput (String.toInt >> Maybe.withDefault 40 >> UpdateDaysToShow)
                            ]
                            []
                        , span [] [ text (String.fromInt maxDaysToShow) ]
                        ]

                  else
                    text ""
                ]
            ]
        , div [ class "space-y-6" ]
            (getDaysToShow model.currentTime
                |> groupByMonth
                |> List.map
                    (\( month, dates ) ->
                        div [ class "mt-4" ]
                            [ div [ class "px-4 py-2" ]
                                [ h3 [ class "text-sm font-medium text-amber-800" ]
                                    [ text (monthToString month) ]
                                ]
                            , div [ class "mt-2 grid grid-cols-7 text-center text-xs leading-6 text-amber-500" ]
                                (List.map (\day -> div [] [ text day ]) [ "M", "T", "W", "T", "F", "S", "S" ])
                            , div [ class "mt-2 grid grid-cols-7 gap-1 p-2" ]
                                (dates
                                    |> List.map
                                        (\date ->
                                            viewDay date.time date.isDummy
                                        )
                                )
                            ]
                    )
            )
        ]


isSameDay : Time.Posix -> Time.Posix -> Bool
isSameDay date1 date2 =
    Time.toDay Time.utc date1
        == Time.toDay Time.utc date2
        && Time.toMonth Time.utc date1
        == Time.toMonth Time.utc date2
        && Time.toYear Time.utc date1
        == Time.toYear Time.utc date2


viewPopover : DayStats -> Html Msg
viewPopover dayStats =
    div
        [ class """
            fixed inset-0 z-50
            flex justify-end
            bg-black/30
            transition-opacity duration-300
          """
        , onClick CloseSlider -- Close when clicking backdrop
        ]
        [ div
            [ class """
                w-full max-w-md h-full
                bg-white shadow-xl
                transform transition-transform duration-300 ease-out
                translate-x-0
                animate-slide-in
                overflow-y-auto
              """
            , style "min-width" "320px"
            , onClick NoOp -- Prevent clicks inside panel from closing
            ]
            [ div [ class "sticky top-0 bg-white border-b border-amber-100 p-4 flex justify-between items-center" ]
                [ div [ class "text-lg font-medium text-amber-900" ]
                    [ text (formatDate dayStats.timestamp) ]
                , button
                    [ class """
                        w-8 h-8
                        flex items-center justify-center
                        rounded-full
                        bg-amber-100 hover:bg-amber-200
                        text-amber-800 text-lg
                        transition-colors
                      """
                    , onClick CloseSlider
                    ]
                    [ text "×" ]
                ]
            , div [ class "p-4 space-y-6" ]
                [ div [ class "space-y-2" ]
                    [ div [ class "text-2xl font-bold text-amber-900" ]
                        [ text (String.fromInt dayStats.totalReps)
                        , span [ class "text-lg font-normal text-amber-700 ml-2" ]
                            [ text "total reps" ]
                        ]
                    , if dayStats.sessionCount > 1 then
                        div [ class "text-amber-800" ]
                            [ div [] [ text ("Sessions: " ++ String.fromInt dayStats.sessionCount) ]
                            , div [] [ text ("Average: " ++ String.fromInt (dayStats.totalReps // dayStats.sessionCount) ++ " per session") ]
                            ]

                      else
                        text ""
                    ]
                , div [ class "border-t border-amber-100 pt-4" ]
                    [ div [ class "text-sm font-medium text-amber-800 mb-3" ]
                        [ text "Sessions" ]
                    , div [ class "space-y-3" ]
                        (List.map
                            (\session ->
                                div [ class "flex flex-col p-3 bg-amber-50 rounded-lg" ]
                                    [ div [ class "flex items-center justify-between" ]
                                        [ div [ class "text-amber-800" ]
                                            [ text (formatTime session.timestamp) ]
                                        , case session.repGoal of
                                            Just goal ->
                                                let
                                                    percentage : String
                                                    percentage =
                                                        (toFloat session.reps / toFloat goal * 100)
                                                            |> round
                                                            |> String.fromInt
                                                in
                                                div [ class "text-right" ]
                                                    [ div [ class "font-medium text-amber-900" ]
                                                        [ text (String.fromInt session.reps ++ " of " ++ String.fromInt goal ++ " reps") ]
                                                    , div [ class "text-sm text-amber-700" ]
                                                        [ text (percentage ++ "% completed") ]
                                                    ]

                                            Nothing ->
                                                text (String.fromInt session.reps ++ " reps")
                                        ]
                                    ]
                            )
                            dayStats.sessions
                        )
                    ]
                ]
            ]
        ]



-- HELPERS


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


formatDate : Time.Posix -> String
formatDate time =
    String.fromInt (Time.toYear Time.utc time)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (monthToInt (Time.toMonth Time.utc time)))
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toDay Time.utc time))


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12



-- Additional helper functions
-- Add this new type to store the aggregated workout data


type alias DayStats =
    { totalReps : Int
    , sessionCount : Int
    , timestamp : Time.Posix
    , sessions : List WorkoutResult
    }


formatTime : Time.Posix -> String
formatTime time =
    let
        hour : String
        hour =
            String.fromInt (Time.toHour Time.utc time)
                |> String.padLeft 2 '0'

        minute : String
        minute =
            String.fromInt (Time.toMinute Time.utc time)
                |> String.padLeft 2 '0'
    in
    hour ++ ":" ++ minute
