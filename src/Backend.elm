module Backend exposing (..)

import Casting exposing (CastingChoices, whichPartsAreActor)
import Dict
import Env
import Http
import Json.Decode
import Lamdera exposing (ClientId, SessionId)
import Set
import Task
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


type alias Msg =
    BackendMsg


app :
    { init : ( Model, Cmd Msg )
    , update : Msg -> Model -> ( Model, Cmd Msg )
    , updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd Msg )
    , subscriptions : Model -> Sub Msg
    }
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( { library = EmptyLibrary
      , errorCount = Dict.empty
      , log = []
      , staleTimer = TimerNotSet
      , s3UrlAtLastFetch = Nothing
      }
    , Cmd.none
    )



--  _   _           _       _
-- | | | |_ __   __| | __ _| |_ ___  ___
-- | | | | '_ \ / _` |/ _` | __/ _ \/ __|
-- | |_| | |_) | (_| | (_| | ||  __/\__ \
--  \___/| .__/ \__,_|\__,_|\__\___||___/
--       |_|


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd Msg )
updateFromFrontend sessionId _ msg model =
    case msg of
        -- App
        ClientInit ->
            clientInitHelper sessionId model

        JoinProduction name id ->
            joinProductionHelper model sessionId name id

        ResetProductions ->
            ( { model | library = mapProductions (always Dict.empty) model.library }
            , Cmd.none
            )
                |> logging "Productions reset by client"

        -- Director
        MakeInvitation script ->
            shareScript sessionId model script

        ShareProduction casting ->
            shareCasting model casting

        -- Actor
        AdvanceCue ->
            advanceCueHelper model


advanceCueHelper : Model -> ( Model, Cmd BackendMsg )
advanceCueHelper model =
    -- TODO Move FullLibrary to own Productions.elm module
    case model.library of
        FullLibrary { productions } ->
            case List.head (Dict.values productions) of
                Just production ->
                    let
                        tellActors message =
                            Dict.keys production.namesBySessionId
                                |> List.map Lamdera.sendToFrontend
                                |> List.map (\f -> f message)
                                |> Cmd.batch

                        directorInCast =
                            whichPartsAreActor "Director (you)" production.casting
                                |> List.isEmpty
                                |> not

                        setLineNumber _ p =
                            -- TODO Advance one production instead of all of them
                            { p | status = p.status + 1 }
                    in
                    ( { model | library = mapProductions (Dict.map setLineNumber) model.library }
                    , Cmd.batch
                        [ tellActors IncrementLineNumber
                        , Task.perform GotSetTimerMoment Time.now
                        , if directorInCast then
                            Lamdera.sendToFrontend production.directorId IncrementLineNumber

                          else
                            Cmd.none
                        ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotScriptList sessionId response ->
            gotScriptListHelper model sessionId response

        FetchScript name _ ->
            case model.library of
                Updating id progress ->
                    ( { model
                        | log = ("Fetching script " ++ name) :: model.log
                        , library = Updating id { progress | fetching = True }
                      }
                    , fetchScript name
                    )

                _ ->
                    -- Shouldn't happen
                    ( model, Cmd.none )

        FetchedScript name response ->
            case response of
                Ok script ->
                    fetchedScriptHelper model name script

                Err e ->
                    errorHelper model name e

        GotSetTimerMoment time ->
            ( { model | staleTimer = TimerSet time }, Cmd.none )

        GotCheckTimerMoment time ->
            checkTimerHelper model time



--  _   _           _       _         _   _      _
-- | | | |_ __   __| | __ _| |_ ___  | | | | ___| |_ __   ___ _ __ ___
-- | | | | '_ \ / _` |/ _` | __/ _ \ | |_| |/ _ \ | '_ \ / _ \ '__/ __|
-- | |_| | |_) | (_| | (_| | ||  __/ |  _  |  __/ | |_) |  __/ |  \__ \
--  \___/| .__/ \__,_|\__,_|\__\___| |_| |_|\___|_| .__/ \___|_|  |___/
--       |_|                                      |_|


joinProductionHelper : Model -> SessionId -> String -> SessionId -> ( Model, Cmd Msg )
joinProductionHelper model actorSessionId name directorSessionId =
    let
        setName _ production =
            { production
                | namesBySessionId =
                    Dict.insert actorSessionId name production.namesBySessionId
            }
    in
    ( { model | library = mapProductions (Dict.map setName) model.library }
    , Cmd.batch
        [ Lamdera.sendToFrontend directorSessionId (ActorJoined name actorSessionId)
        , Task.perform GotSetTimerMoment Time.now
        ]
    )


type NewClient
    = ClientBeforeLibraryLoaded
    | NoActiveProduction (List Script)
    | CurrentActor Production String
    | CurrentDirector (List Script)
    | InvitedActor Production
    | Spectator


clientInitHelper : SessionId -> Model -> ( Model, Cmd Msg )
clientInitHelper sessionId model =
    categorizeClient sessionId model
        |> newClientAction sessionId model
        |> logging ("Client Joined (" ++ sessionId ++ ")")


categorizeClient : SessionId -> Model -> NewClient
categorizeClient sessionId model =
    case model.library of
        FullLibrary { scripts, productions } ->
            case Dict.toList productions of
                -- TODO Enable multiple productions instead of overwriting one
                ( _, production ) :: [] ->
                    selectProductionClient sessionId scripts production

                _ ->
                    NoActiveProduction scripts

        _ ->
            ClientBeforeLibraryLoaded


selectProductionClient : SessionId -> List Script -> Production -> NewClient
selectProductionClient sessionId scripts production =
    case Dict.get sessionId production.namesBySessionId of
        Just name ->
            CurrentActor production name

        Nothing ->
            if sessionId == production.directorId then
                CurrentDirector scripts

            else
            -- If actor joins while casting, invite them
            if
                List.length production.casting > 0
                -- Show was cast already
            then
                Spectator

            else
                InvitedActor production


newClientAction : SessionId -> Model -> NewClient -> ( Model, Cmd Msg )
newClientAction sessionId model client =
    case client of
        CurrentActor production name ->
            ( model
            , Lamdera.sendToFrontend sessionId
                (SetState
                    { script = production.script
                    , name = name
                    , casting = production.casting
                    , lineNumber = production.status
                    }
                )
            )

        ClientBeforeLibraryLoaded ->
            fetchLibraryHelper sessionId model

        InvitedActor production ->
            ( model
            , Lamdera.sendToFrontend sessionId (ConsiderInvite production.script production.directorId)
            )

        CurrentDirector scripts ->
            ( model, Lamdera.sendToFrontend sessionId (LoadLibrary scripts) )

        NoActiveProduction scripts ->
            if model.s3UrlAtLastFetch == Just Env.s3Url then
                ( model
                , Lamdera.sendToFrontend sessionId (LoadLibrary scripts)
                )

            else
                fetchLibraryHelper sessionId model

        Spectator ->
            ( model, Lamdera.sendToFrontend sessionId JoinedAsSpectator )


fetchLibraryHelper : SessionId -> Model -> ( Model, Cmd Msg )
fetchLibraryHelper sessionId model =
    let
        newModel =
            { model | s3UrlAtLastFetch = Just Env.s3Url }

        scriptIndexDecoder =
            Json.Decode.list Json.Decode.string

        fetchRequest =
            Http.get
                { url = Env.s3Url ++ "play_list.json"
                , expect =
                    Http.expectJson
                        (GotScriptList sessionId)
                        scriptIndexDecoder
                }
    in
    case model.library of
        FullLibrary _ ->
            ( newModel, fetchRequest )
                |> logging "New s3Url detected. Attempting to fetch plays..."

        EmptyLibrary ->
            ( newModel, fetchRequest )
                |> logging "Library is empty. Attempting to fetch plays..."

        Updating _ _ ->
            ( model, Cmd.none )


shareScript : SessionId -> Model -> Script -> ( Model, Cmd Msg )
shareScript directorSessionId model script =
    -- For now, everyone joins a production if you share it.
    -- There is only one production, overwritten by any director.
    let
        productions =
            Dict.fromList
                [ ( directorSessionId
                  , { directorId = directorSessionId
                    , status = 0
                    , script = script
                    , casting = []
                    , namesBySessionId = Dict.empty
                    }
                  )
                ]
    in
    ( { model | library = mapProductions (\_ -> productions) model.library }
    , Cmd.none
    )


shareCasting : Model -> CastingChoices -> ( Model, Cmd Msg )
shareCasting model casting =
    case model.library of
        FullLibrary { productions } ->
            case List.head (Dict.values productions) of
                Just production ->
                    let
                        tellActors message =
                            Dict.keys production.namesBySessionId
                                |> List.map Lamdera.sendToFrontend
                                |> List.map (\f -> f message)
                                |> Cmd.batch

                        directorInCast =
                            whichPartsAreActor "Director (you)" casting
                                |> List.isEmpty
                                |> not

                        setCast _ p =
                            { p | casting = casting }
                    in
                    ( { model | library = mapProductions (Dict.map setCast) model.library }
                    , Cmd.batch
                        [ tellActors (StartCueing casting)
                        , Task.perform GotSetTimerMoment Time.now
                        , if directorInCast then
                            Lamdera.sendToFrontend production.directorId (StartCueing casting)

                          else
                            Cmd.none
                        ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


gotScriptListHelper :
    Model
    -> SessionId
    -> Result Http.Error (List String)
    -> ( Model, Cmd Msg )
gotScriptListHelper model sessionId response =
    case response of
        Ok list ->
            ( { model
                | library =
                    Updating sessionId
                        { added = Set.empty
                        , notAdded = Set.fromList list
                        , scripts = []
                        , fetching = False
                        }
              }
            , Cmd.none
            )

        Err e ->
            ( model, Cmd.none )
                |> logging
                    ("When fetching play_list.json, encountered "
                        ++ errorToString e
                        ++ "\n"
                    )


fetchedScriptHelper : Model -> String -> Script -> ( Model, Cmd Msg )
fetchedScriptHelper model name script =
    case model.library of
        Updating sessionId { added, notAdded, scripts } ->
            let
                progress =
                    { added = Set.insert name added
                    , notAdded = Set.remove name notAdded
                    , scripts = scripts ++ [ script ]
                    , fetching = False
                    }
            in
            ( if Set.size progress.notAdded == 0 then
                { model
                    | log = "Finished loading library" :: model.log
                    , library =
                        FullLibrary
                            { titles = Set.toList progress.added
                            , scripts = progress.scripts
                            , productions = Dict.empty
                            }
                }

              else
                { model | library = Updating sessionId progress }
            , Lamdera.sendToFrontend sessionId (LoadLibrary progress.scripts)
            )

        _ ->
            -- Ignore fetch if no longer updating
            ( model, Cmd.none )



-- Getting scripts might fail, and we want to stop trying after a bit


errorHelper : Model -> String -> Http.Error -> ( Model, Cmd Msg )
errorHelper model name e =
    let
        incrementError maybeCount =
            Maybe.map ((+) 1) maybeCount
                |> Maybe.withDefault 0
                |> Just

        errors =
            Dict.get name model.errorCount
                |> Maybe.withDefault 0

        newModel =
            { model
                | errorCount = Dict.update name incrementError model.errorCount
            }
    in
    if errors >= 1 then
        ---- We stop asking for a script after 1 failure
        -- Change to 1 from 5 which overwhelmed server
        ( { newModel | library = EmptyLibrary }, Cmd.none )
            |> logging
                ("When fetching "
                    ++ name
                    ++ ", encountered "
                    ++ errorToString e
                    ++ "\n"
                )

    else
        ( newModel, Cmd.none )


errorToString : Http.Error -> String
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


checkTimerHelper : { library : State, errorCount : Dict.Dict String Int, log : List String, staleTimer : Timer, s3UrlAtLastFetch : Maybe String } -> Time.Posix -> ( Model, Cmd Msg )
checkTimerHelper model time =
    case model.staleTimer of
        TimerSet timer ->
            let
                now =
                    Time.posixToMillis time

                limitMillis =
                    1000 * 60 * 10

                staleTimer =
                    Time.posixToMillis timer + limitMillis
            in
            if now > staleTimer then
                ( { model
                    | staleTimer = TimerNotSet
                    , library = mapProductions (\_ -> Dict.empty) model.library
                  }
                , Cmd.none
                )
                    |> logging "Ending production which ran for 10 minutes without any actions"

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )



--    ___                                          _
--  / ___|___  _ __ ___  _ __ ___   __ _ _ __   __| |___
-- | |   / _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` / __|
-- | |__| (_) | | | | | | | | | | | (_| | | | | (_| \__ \
--  \____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|___/
--


fetchScript : String -> Cmd Msg
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
        { url = Env.s3Url ++ Url.percentEncode name
        , expect = Http.expectJson (FetchedScript name) scriptDecoder
        }


type alias ScriptLine =
    { speaker : String, line : String, title : String, part : String }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ fetchScriptTrigger model
        , checkStaleProductionTrigger model
        ]


checkStaleProductionTrigger : { a | staleTimer : Timer } -> Sub BackendMsg
checkStaleProductionTrigger model =
    case model.staleTimer of
        TimerSet _ ->
            Time.every 1000 GotCheckTimerMoment

        TimerNotSet ->
            Sub.none


fetchScriptTrigger : { a | library : State } -> Sub BackendMsg
fetchScriptTrigger model =
    case model.library of
        Updating _ { notAdded, fetching } ->
            case List.head (Set.toList notAdded) of
                Just name ->
                    if fetching then
                        Sub.none

                    else
                        Time.every 300 (FetchScript name)

                Nothing ->
                    Sub.none

        _ ->
            Sub.none



--   ____                           _
--  / ___|___  _ ____   _____ _ __ (_) ___ _ __   ___ ___
-- | |   / _ \| '_ \ \ / / _ \ '_ \| |/ _ \ '_ \ / __/ _ \
-- | |__| (_) | | | \ V /  __/ | | | |  __/ | | | (_|  __/
--  \____\___/|_| |_|\_/ \___|_| |_|_|\___|_| |_|\___\___|
--


mapProductions :
    (Dict.Dict String Production -> Dict.Dict String Production)
    -> State
    -> State
mapProductions f library =
    case library of
        FullLibrary ({ productions } as lib) ->
            FullLibrary { lib | productions = f productions }

        _ ->
            library


logging : String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
logging log ( model, cmd ) =
    ( { model | log = log :: model.log }
    , Cmd.batch [ cmd, Lamdera.broadcast (ReportErrors (log :: model.log)) ]
    )
