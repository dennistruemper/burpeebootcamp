module Effect exposing
    ( Effect
    , none, batch
    , sendCmd
    , pushRoute, replaceRoute
    , pushRoutePath, replaceRoutePath
    , map, toCmd
    , calculateRepGoal, getRandom, getTime, getTimeZone, logError, newCurrentBurpee, playSound, storeBurpeeVariant, storeWorkout, storeWorkoutResult
    )

{-|

@docs Effect

@docs none, batch
@docs sendCmd

@docs pushRoute, replaceRoute
@docs pushRoutePath, replaceRoutePath

@docs map, toCmd

-}

import Browser.Navigation
import Burpee exposing (Burpee)
import Dict exposing (Dict)
import Json.Encode
import Ports
import Random
import Route
import Route.Path
import Shared.Model
import Shared.Msg
import Sound exposing (Sound)
import Task
import Time
import Url exposing (Url)
import WorkoutResult exposing (WorkoutResult)



-- Add the Sound type


type Effect msg
    = -- BASICS
      None
    | Batch (List (Effect msg))
    | SendCmd (Cmd msg)
      -- ROUTING
    | PushUrl String
    | ReplaceUrl String
      -- SHARED
    | SendSharedMsg Shared.Msg.Msg
    | SendMessageToJavaScript
        { tag : String
        , data : Json.Encode.Value
        }



-- BASICS


{-| Don't send any effect.
-}
none : Effect msg
none =
    None


{-| Send multiple effects at once.
-}
batch : List (Effect msg) -> Effect msg
batch =
    Batch


{-| Send a normal `Cmd msg` as an effect, something like `Http.get` or `Random.generate`.
-}
sendCmd : Cmd msg -> Effect msg
sendCmd =
    SendCmd



-- SHARED


{-| Set the new current burpee.
-}
newCurrentBurpee : Burpee -> Effect msg
newCurrentBurpee burpee =
    SendSharedMsg (Shared.Msg.BurpeePicked burpee)


storeWorkoutResult : WorkoutResult -> Effect msg
storeWorkoutResult result =
    SendSharedMsg (Shared.Msg.StoreWorkoutResult result)


getTime : (Time.Posix -> msg) -> Effect msg
getTime gotTimeMsg =
    SendCmd (Time.now |> Task.perform gotTimeMsg)


getTimeZone : (Time.Zone -> msg) -> Effect msg
getTimeZone gotTimeZoneMsg =
    SendCmd (Time.here |> Task.perform gotTimeZoneMsg)


storeBurpeeVariant : Burpee -> Effect msg
storeBurpeeVariant burpee =
    SendMessageToJavaScript
        { tag = "StoreBurpeeVariant"
        , data = Burpee.encodeJson burpee
        }


storeWorkout : WorkoutResult -> Effect msg
storeWorkout workout =
    SendMessageToJavaScript
        { tag = "StoreWorkout"
        , data = WorkoutResult.encodeJson workout
        }


logError : String -> Effect msg
logError message =
    SendMessageToJavaScript
        { tag = "LogError"
        , data = Json.Encode.string message
        }



-- ROUTING


{-| Set the new route, and make the back button go back to the current route.
-}
pushRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
pushRoute route =
    PushUrl (Route.toString route)


{-| Same as `Effect.pushRoute`, but without `query` or `hash` support
-}
pushRoutePath : Route.Path.Path -> Effect msg
pushRoutePath path =
    PushUrl (Route.Path.toString path)


{-| Set the new route, but replace the previous one, so clicking the back
button **won't** go back to the previous route.
-}
replaceRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
replaceRoute route =
    ReplaceUrl (Route.toString route)


{-| Same as `Effect.replaceRoute`, but without `query` or `hash` support
-}
replaceRoutePath : Route.Path.Path -> Effect msg
replaceRoutePath path =
    ReplaceUrl (Route.Path.toString path)


{-| Calculate the next rep goal based on workout history.
-}
calculateRepGoal : (Time.Posix -> msg) -> Effect msg
calculateRepGoal gotTimeMsg =
    SendCmd (Time.now |> Task.perform gotTimeMsg)


getRandom : Random.Generator a -> (a -> msg) -> Effect msg
getRandom generator toMsg =
    SendCmd (Random.generate toMsg generator)


playSound : Sound -> Effect msg
playSound sound =
    SendMessageToJavaScript
        { tag = "PlaySound"
        , data = Json.Encode.string (Sound.toString sound)
        }



-- INTERNALS


{-| Elm Land depends on this function to connect pages and layouts
together into the overall app.
-}
map : (msg1 -> msg2) -> Effect msg1 -> Effect msg2
map fn effect =
    case effect of
        None ->
            None

        Batch list ->
            Batch (List.map (map fn) list)

        SendCmd cmd ->
            SendCmd (Cmd.map fn cmd)

        PushUrl url ->
            PushUrl url

        ReplaceUrl url ->
            ReplaceUrl url

        SendSharedMsg sharedMsg ->
            SendSharedMsg sharedMsg

        SendMessageToJavaScript message ->
            SendMessageToJavaScript message


{-| Elm Land depends on this function to perform your effects.
-}
toCmd :
    { key : Browser.Navigation.Key
    , url : Url
    , shared : Shared.Model.Model
    , fromSharedMsg : Shared.Msg.Msg -> msg
    , batch : List msg -> msg
    , toCmd : msg -> Cmd msg
    }
    -> Effect msg
    -> Cmd msg
toCmd options effect =
    case effect of
        None ->
            Cmd.none

        Batch list ->
            Cmd.batch (List.map (toCmd options) list)

        SendCmd cmd ->
            cmd

        PushUrl url ->
            Browser.Navigation.pushUrl options.key url

        ReplaceUrl url ->
            Browser.Navigation.replaceUrl options.key url

        SendSharedMsg sharedMsg ->
            Task.succeed sharedMsg
                |> Task.perform options.fromSharedMsg

        SendMessageToJavaScript message ->
            Ports.toJs message
