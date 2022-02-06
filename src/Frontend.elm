module Frontend exposing (..)

import Actor
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Client exposing (Msg(..), PlatformCmd(..), PlatformResponse(..))
import Director
import Env
import Html
import Html.Attributes as Attr
import Html.Styled as Html exposing (toUnstyled)
import Lamdera
import Task
import Types
import Url



--  ____  _       _    __
-- |  _ \| | __ _| |_ / _| ___  _ __ _ __ ___
-- | |_) | |/ _` | __| |_ / _ \| '__| '_ ` _ \
-- |  __/| | (_| | |_|  _| (_) | |  | | | | | |
-- |_|   |_|\__,_|\__|_|  \___/|_|  |_| |_| |_|
-- The heart of the lamdera platform for cuecannon is
-- mapped in these functions


platformCmdTransform platformCmd =
    case platformCmd of
        Client.NoCmd ->
            Cmd.none

        Client.ClientInit ->
            Lamdera.sendToBackend Types.ClientInit

        DirectorPC subCommand ->
            case subCommand of
                Director.MakeInvitation script ->
                    Lamdera.sendToBackend (Types.MakeInvitation script)

                Director.ShareProduction casting ->
                    Lamdera.sendToBackend (Types.ShareProduction casting)

                Director.NoCmd ->
                    Cmd.none

        ActorPC subCommand ->
            case subCommand of
                Actor.AdvanceCue ->
                    Lamdera.sendToBackend Types.AdvanceCue

                Actor.JoinProduction name id ->
                    Lamdera.sendToBackend (Types.JoinProduction name id)

                Actor.NoCmd ->
                    Cmd.none


updateFromBackend :
    Types.ToFrontend
    -> Model
    -> ( Model, Cmd Msg )
updateFromBackend msg model =
    case msg of
        Types.ReportErrors errors ->
            ( model, relayPlatformResponse (Client.ReportErrors errors) )

        Types.LoadLibrary s ->
            ( model
            , relayPlatformResponse (DirectorPR (Director.AddScripts s Env.host))
            )

        Types.ActorJoined name clientId ->
            ( model, relayPlatformResponse (DirectorPR (Director.ActorJoined name clientId)) )

        Types.ConsiderInvite script clientId ->
            ( model, relayPlatformResponse (ActorPR (Actor.ConsiderInvite script clientId)) )

        Types.StartCueing casting ->
            ( model, relayPlatformResponse (ActorPR (Actor.StartCueing casting)) )

        Types.IncrementLineNumber ->
            ( model, relayPlatformResponse (ActorPR Actor.IncrementLineNumber) )

        Types.SetState state ->
            ( model, relayPlatformResponse (ActorPR (Actor.SetState state)) )


subscriptions m =
    Sub.none
        |> Sub.map onlyPlatformMessage



-- __        ___      _
-- \ \      / (_)_ __(_)_ __   __ _
--  \ \ /\ / /| | '__| | '_ \ / _` |
--   \ V  V / | | |  | | | | | (_| |
--    \_/\_/  |_|_|  |_|_| |_|\__, |
--                            |___/
-- Wiring up the lamdera platform to the cueCannon client
-- has some surprising types! It shouldn't change much though.


type alias Model =
    Types.FrontendModel


type alias Msg =
    Types.FrontendMsg


relayPlatformResponse : PlatformResponse -> Cmd Msg
relayPlatformResponse msg =
    Task.succeed ()
        |> Task.perform (\_ -> OnlyPlatformResponse msg)
        |> Cmd.map onlyPlatformMessage



{- onlyPlatformMessage is to ensure that the lamdera platform is only generating
   the expected responses to the cue cannon client
-}


onlyPlatformMessage : Msg -> Msg
onlyPlatformMessage msg =
    case msg of
        OnlyPlatformResponse x ->
            OnlyPlatformResponse x

        _ ->
            OnlyPlatformResponse NoResponse


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = Client.doNothing
        , onUrlChange = Client.doNothing
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }


init : Url.Url -> Nav.Key -> ( Types.FrontendModel, Cmd Msg )
init url key =
    ( { key = key
      , cueCannonModel = Client.initialModel
      }
    , Cmd.batch
        [ Lamdera.sendToBackend Types.ClientInit
        ]
    )


update msg model =
    let
        ( newModel, platformCmd ) =
            Client.update msg model.cueCannonModel
    in
    ( { model | cueCannonModel = newModel }
    , platformCmdTransform platformCmd
    )


view : Model -> Browser.Document Msg
view model =
    { title = ""
    , body =
        [ (toUnstyled << Client.view) model.cueCannonModel ]
    }
