module Backend exposing (..)

import Client exposing (Script(..))
import Env
import Html
import Http
import Json.Decode
import Lamdera exposing (ClientId, SessionId)
import Set
import Time
import Types exposing (..)
import Url


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
    ( { message = "Hello!", library = EmptyLibrary }
    , Cmd.none
    )


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


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        GotScriptList clientId response ->
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

        FetchScript name _ ->
            ( model, fetchScript name )

        FetchedScript name response ->
            case response of
                Ok script ->
                    fetchedScriptHelper model name script

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
