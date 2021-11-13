module Backend exposing (..)

import Dict
import Env
import Html
import Http
import Json.Decode
import Lamdera exposing (ClientId, SessionId)
import Set
import Time
import Types exposing (..)
import Url



--  _____ _            _____ _
-- |_   _| |__   ___  | ____| |_ __ ___
--   | | | '_ \ / _ \ |  _| | | '_ ` _ \
--   | | | | | |  __/ | |___| | | | | | |
--   |_| |_| |_|\___| |_____|_|_| |_| |_|
--
--     _             _     _ _            _
--    / \   _ __ ___| |__ (_) |_ ___  ___| |_ _   _ _ __ ___
--   / _ \ | '__/ __| '_ \| | __/ _ \/ __| __| | | | '__/ _ \
--  / ___ \| | | (__| | | | | ||  __/ (__| |_| |_| | | |  __/
-- /_/   \_\_|  \___|_| |_|_|\__\___|\___|\__|\__,_|_|  \___|
--


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { message = "Hello!", library = EmptyLibrary, errorCount = Dict.empty, errorLog = [] }
    , Cmd.none
    )



--  _   _           _       _
-- | | | |_ __   __| | __ _| |_ ___  ___
-- | | | | '_ \ / _` |/ _` | __/ _ \/ __|
-- | |_| | |_) | (_| | (_| | ||  __/\__ \
--  \___/| .__/ \__,_|\__,_|\__\___||___/
--       |_|


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        -- App
        JoinProduction name id ->
            joinProductionHelper model clientId name id

        FetchScripts ->
            fetchScriptHelper clientId model

        -- Director
        MakeInvitation script ->
            makeInvitationHelper clientId model script

        ShareProduction casting ->
            shareProductionHelper model casting

        AdvanceCue ->
            ( model, Lamdera.broadcast IncrementLineNumber )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        GotScriptList clientId response ->
            gotScriptListHelper model clientId response

        FetchScript name _ ->
            ( model, fetchScript name )

        FetchedScript name response ->
            case response of
                Ok script ->
                    fetchedScriptHelper model name script

                Err e ->
                    errorHelper model name e



--  _   _           _       _         _   _      _
-- | | | |_ __   __| | __ _| |_ ___  | | | | ___| |_ __   ___ _ __ ___
-- | | | | '_ \ / _` |/ _` | __/ _ \ | |_| |/ _ \ | '_ \ / _ \ '__/ __|
-- | |_| | |_) | (_| | (_| | ||  __/ |  _  |  __/ | |_) |  __/ |  \__ \
--  \___/| .__/ \__,_|\__,_|\__\___| |_| |_|\___|_| .__/ \___|_|  |___/
--       |_|                                      |_|


joinProductionHelper model actorClientId name directorClientId =
    ( model
    , Lamdera.sendToFrontend directorClientId (ActorJoined name actorClientId)
    )


fetchScriptHelper clientId model =
    case model.library of
        EmptyLibrary ->
            let
                scriptIndexDecoder =
                    Json.Decode.list Json.Decode.string
            in
            ( model
            , Http.get
                { url = Env.s3Url
                , expect = Http.expectJson (GotScriptList clientId) scriptIndexDecoder
                }
            )

        Library lib ->
            ( model, Lamdera.sendToFrontend clientId (LoadLibrary lib.scripts) )

        Updating _ _ ->
            ( model, Cmd.none )


makeInvitationHelper directorClientId model script =
    -- For now, everyone joins a production if you share it.
    ( model
    , Lamdera.broadcast (ConsiderInvite script directorClientId)
    )


shareProductionHelper model casting =
    ( model, Lamdera.broadcast (StartCueing casting) )


gotScriptListHelper model clientId response =
    case response of
        Ok list ->
            ( { model
                | library =
                    Updating clientId
                        { added = Set.empty
                        , notAdded = Set.fromList list
                        , scripts = []
                        }
              }
            , Cmd.none
            )

        Err e ->
            ( model, Cmd.none )


fetchedScriptHelper : Model -> String -> Script -> ( Model, Cmd BackendMsg )
fetchedScriptHelper model name script =
    case model.library of
        Updating clientId { added, notAdded, scripts } ->
            let
                progress =
                    { added = Set.insert name added
                    , notAdded = Set.remove name notAdded
                    , scripts = scripts ++ [ script ]
                    }

                newLibrary =
                    if Set.size progress.notAdded == 0 then
                        Library
                            { titles = Set.toList progress.added
                            , scripts = progress.scripts
                            }

                    else
                        Updating clientId progress
            in
            ( { model | library = newLibrary }
            , Lamdera.sendToFrontend clientId (LoadLibrary progress.scripts)
            )

        _ ->
            -- Ignore fetch if no longer updating
            ( model, Cmd.none )



-- Getting scripts might fail, and we want to stop trying after a bit


errorHelper model name e =
    let
        formatError =
            "When fetching " ++ name ++ ", encountered " ++ errorToString e ++ "\n"

        incrementError maybeCount =
            Maybe.map ((+) 1) maybeCount
                |> Maybe.withDefault 0
                |> Just

        errors =
            Dict.get name model.errorCount
                |> Maybe.withDefault 0

        newModel =
            { model
                | errorLog = formatError :: model.errorLog
                , errorCount = Dict.update name incrementError model.errorCount
            }
    in
    if errors > 5 then
        -- We stop asking for a script after 5 failures
        ( newModel
        , Lamdera.broadcast (ReportErrors newModel.errorLog)
        )

    else
        ( newModel, Cmd.none )


errorToString err =
    -- https://package.elm-lang.org/packages/elm/http/latest/Http#expectStringResponse
    -- BadUrl means you did not provide a valid URL.
    -- Timeout means it took too long to get a response.
    -- NetworkError means the user turned off their wifi, went in a cave, etc.
    -- BadStatus means you got a response back, but the status code indicates failure.
    -- BadBody means you got a response back with a nice status code, but the body of the response was something unexpected. The String in this case is a debugging message that explains what went wrong with your JSON decoder or whatever.
    case err of
        Http.BadUrl s ->
            "Elm.HTTP bad url error: " ++ s

        Http.Timeout ->
            "Elm.HTTP timeout error"

        Http.NetworkError ->
            "Elm.HTTP network error"

        Http.BadStatus i ->
            "Elm.HTTP bad status error: " ++ String.fromInt i

        Http.BadBody s ->
            "Elm.HTTP bad body error: " ++ s



--    ___                                          _
--  / ___|___  _ __ ___  _ __ ___   __ _ _ __   __| |___
-- | |   / _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` / __|
-- | |__| (_) | | | | | | | | | | | (_| | | | | (_| \__ \
--  \____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|___/
--


fetchScript : String -> Cmd BackendMsg
fetchScript name =
    let
        promptDecoder : Json.Decode.Decoder ScriptLine
        promptDecoder =
            Json.Decode.map4 ScriptLine
                (Json.Decode.field "s" Json.Decode.string)
                (Json.Decode.field "l" Json.Decode.string)
                (Json.Decode.field "t" Json.Decode.string)
                (Json.Decode.field "p" Json.Decode.string)

        scriptDecoder : Json.Decode.Decoder Script
        scriptDecoder =
            Json.Decode.list promptDecoder
                |> Json.Decode.andThen (\scriptLines -> Json.Decode.succeed (Script name scriptLines))
    in
    Http.get
        { url = "http://macbeezy.s3.us-east-2.amazonaws.com/" ++ Url.percentEncode name
        , expect = Http.expectJson (FetchedScript name) scriptDecoder
        }


type alias ScriptLine =
    { speaker : String, line : String, title : String, part : String }


subscriptions : Model -> Sub BackendMsg
subscriptions model =
    case model.library of
        Updating _ { added, notAdded } ->
            case List.head (Set.toList notAdded) of
                Just name ->
                    Time.every 300 (FetchScript name)

                Nothing ->
                    Sub.none

        _ ->
            Sub.none
