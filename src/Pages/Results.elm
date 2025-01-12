module Pages.Results exposing (Model, Msg, page)

import Burpee exposing (Burpee)
import Dict
import Effect exposing (Effect)
import Html exposing (Html, button, div, h1, h2, h3, input, span, text, time)
import Html.Attributes exposing (class, datetime, max, min, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import Time
import View exposing (View)
import WorkoutResult exposing (WorkoutResult)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
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
    | SelectDate (Maybe Time.Posix)
    | UpdateDaysToShow Int
    | NavigateToMenu
    | TogglePopover (Maybe Time.Posix)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotCurrentTime time ->
            ( { model | currentTime = time }
            , Effect.none
            )

        SelectDate maybeDate ->
            ( { model | selectedDate = maybeDate }
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Workout History"
    , body =
        case shared.initializing of
            True ->
                [ text "Loading..." ]

            False ->
                [ div [ class "results-container p-4" ]
                    [ div [ class "flex justify-between items-center mb-6" ]
                        [ h1 [ class "results-title text-2xl font-bold" ]
                            [ text "Your Sessions" ]
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
                        month =
                            Time.toMonth Time.utc date

                        year =
                            Time.toYear Time.utc date

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
                                weekday =
                                    Time.toWeekday Time.utc lastDate.time

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
                                oneMonthInMillis =
                                    1000 * 60 * 60 * 24 * 30

                                paddingDates =
                                    List.range 1 paddingCount
                                        |> List.map (\_ -> { time = Time.millisToPosix (Time.posixToMillis lastDate.time + oneMonthInMillis), isDummy = True })

                                result =
                                    paddingDates ++ dates_
                            in
                            result

                -- Helper to get a sortable value for a month/year combination
                getMonthSortValue : List Time.Posix -> Int
                getMonthSortValue dates_ =
                    case List.head dates_ of
                        Just date ->
                            (Time.toYear Time.utc date * 12) + monthToInt (Time.toMonth Time.utc date)

                        Nothing ->
                            0
            in
            dates
                |> List.foldl insertDate Dict.empty
                |> Dict.toList
                |> List.map
                    (\( key, dates_ ) ->
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
                        workoutDay =
                            Time.toDay Time.utc workout.timestamp

                        workoutMonth =
                            Time.toMonth Time.utc workout.timestamp

                        workoutYear =
                            Time.toYear Time.utc workout.timestamp

                        targetDay =
                            Time.toDay Time.utc date

                        targetMonth =
                            Time.toMonth Time.utc date

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

                            firstWorkout :: restWorkouts ->
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
            let
                _ =
                    Debug.log "maxDaysToShow" maxDaysToShow
            in
            Debug.log "maxDaysToShow"
                (maxDaysToShow
                    /= 40
                )

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
                    workout =
                        getWorkout date

                    isToday =
                        Time.toDay Time.utc date
                            == Time.toDay Time.utc model.currentTime
                            && Time.toMonth Time.utc date
                            == Time.toMonth Time.utc model.currentTime
                            && Time.toYear Time.utc date
                            == Time.toYear Time.utc model.currentTime

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
    let
        weekday =
            Time.toWeekday Time.utc dayStats.timestamp

        isFirstColumn =
            weekday == Time.Mon

        isLastColumn =
            weekday == Time.Sun

        ( positionClasses, arrowClasses ) =
            if isFirstColumn then
                ( "left-full top-1/2 -translate-y-1/2 ml-2"
                , "absolute top-1/2 -translate-y-1/2 -left-1.5 w-3 h-3 rotate-45 bg-white border-l border-b border-amber-200"
                )

            else if isLastColumn then
                ( "right-full top-1/2 -translate-y-1/2 mr-2"
                , "absolute top-1/2 -translate-y-1/2 -right-1.5 w-3 h-3 rotate-45 bg-white border-t border-r border-amber-200"
                )

            else
                ( "left-1/2 -translate-x-1/2 top-0 -translate-y-full mt-[-8px]"
                , "absolute top-full left-1/2 -translate-x-1/2 w-3 h-3 rotate-45 bg-white border-l border-b border-amber-200"
                )

        -- Format time as HH:MM
        formatTime : Time.Posix -> String
        formatTime time =
            String.padLeft 2 '0' (String.fromInt (Time.toHour Time.utc time))
                ++ ":"
                ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute Time.utc time))
    in
    div
        [ class """
            absolute z-10
            bg-white p-3 rounded-lg shadow-lg border border-amber-200
            min-w-[200px] max-w-[250px]
            transform origin-bottom
          """
        , class positionClasses
        , style "filter" "drop-shadow(0 2px 4px rgba(0,0,0,0.1))"
        ]
        [ div [ class "relative" ]
            [ button
                [ class """
                    absolute -top-1 -right-1 w-5 h-5
                    flex items-center justify-center
                    rounded-full bg-amber-100 hover:bg-amber-200
                    text-amber-800 text-sm
                    transition-colors
                  """
                , onClick (TogglePopover Nothing)
                ]
                [ text "×" ]
            , div [ class "text-sm space-y-2" ]
                [ div [ class "font-medium text-amber-900" ]
                    [ text (formatDate dayStats.timestamp) ]
                , div [ class "text-amber-800" ]
                    [ div [] [ text ("Total reps: " ++ String.fromInt dayStats.totalReps) ]
                    , if dayStats.sessionCount > 1 then
                        div []
                            [ div [] [ text ("Sessions: " ++ String.fromInt dayStats.sessionCount) ]
                            , div [] [ text ("Average: " ++ String.fromInt (dayStats.totalReps // dayStats.sessionCount) ++ " per session") ]
                            ]

                      else
                        text ""
                    ]
                , div [ class "mt-2 space-y-1" ]
                    (List.map
                        (\session ->
                            div [ class "text-xs text-amber-700" ]
                                [ text (formatTime session.timestamp ++ ": " ++ String.fromInt session.reps ++ " reps") ]
                        )
                        dayStats.sessions
                    )
                ]
            ]
        , div [ class arrowClasses ] []
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


getDaysInMonth : Int -> Time.Month -> List Time.Posix
getDaysInMonth year month =
    let
        -- First day of the target month
        firstOfMonth =
            Time.millisToPosix 1735763869059

        -- Get the weekday of the first day (0 = Sun, 1 = Mon, ..., 6 = Sat)
        firstDayWeekday =
            Time.toWeekday Time.utc firstOfMonth
                |> weekdayToInt
                |> modBy 7

        -- Calculate padding days needed at start (for Monday-based week)
        paddingBefore =
            (firstDayWeekday + 6)
                |> modBy 7

        -- Days in the month
        daysInMonth =
            daysInMonthHelper year month

        -- Calculate padding days needed at end
        paddingAfter =
            (7 - ((paddingBefore + daysInMonth) |> modBy 7))
                |> modBy 7
    in
    List.range 1 31
        |> List.map
            (\n -> Time.posixToMillis firstOfMonth + ((n - 1) * 24 * 60 * 60 * 1000) |> Time.millisToPosix)



-- Additional helper functions


daysInMonthHelper : Int -> Time.Month -> Int
daysInMonthHelper year month =
    case month of
        Time.Jan ->
            31

        Time.Feb ->
            if isLeapYear year then
                29

            else
                28

        Time.Mar ->
            31

        Time.Apr ->
            30

        Time.May ->
            31

        Time.Jun ->
            30

        Time.Jul ->
            31

        Time.Aug ->
            31

        Time.Sep ->
            30

        Time.Oct ->
            31

        Time.Nov ->
            30

        Time.Dec ->
            31


isLeapYear : Int -> Bool
isLeapYear year =
    (modBy 4 year == 0) && ((modBy 100 year /= 0) || (modBy 400 year == 0))


weekdayToInt : Time.Weekday -> Int
weekdayToInt weekday =
    case weekday of
        Time.Mon ->
            1

        Time.Tue ->
            2

        Time.Wed ->
            3

        Time.Thu ->
            4

        Time.Fri ->
            5

        Time.Sat ->
            6

        Time.Sun ->
            0


previousMonth : Time.Month -> Time.Month
previousMonth month =
    case month of
        Time.Jan ->
            Time.Dec

        Time.Feb ->
            Time.Jan

        Time.Mar ->
            Time.Feb

        Time.Apr ->
            Time.Mar

        Time.May ->
            Time.Apr

        Time.Jun ->
            Time.May

        Time.Jul ->
            Time.Jun

        Time.Aug ->
            Time.Jul

        Time.Sep ->
            Time.Aug

        Time.Oct ->
            Time.Sep

        Time.Nov ->
            Time.Oct

        Time.Dec ->
            Time.Nov


nextMonth : Time.Month -> Time.Month
nextMonth month =
    case month of
        Time.Jan ->
            Time.Feb

        Time.Feb ->
            Time.Mar

        Time.Mar ->
            Time.Apr

        Time.Apr ->
            Time.May

        Time.May ->
            Time.Jun

        Time.Jun ->
            Time.Jul

        Time.Jul ->
            Time.Aug

        Time.Aug ->
            Time.Sep

        Time.Sep ->
            Time.Oct

        Time.Oct ->
            Time.Nov

        Time.Nov ->
            Time.Dec

        Time.Dec ->
            Time.Jan



-- Add this new type to store the aggregated workout data


type alias DayStats =
    { totalReps : Int
    , sessionCount : Int
    , timestamp : Time.Posix
    , sessions : List WorkoutResult
    }
