module Frontend exposing (..)

import Actor
import Browser exposing (UrlRequest)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Client exposing (Msg(..), PlatformCmd(..), PlatformResponse(..))
import Director
import Env
import Html.Styled exposing (toUnstyled)
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


platformCmdTransform : PlatformCmd -> Cmd Msg
platformCmdTransform platformCmd =
    case platformCmd of
        Client.NoCmd ->
            Cmd.none

        Client.ClientInit ->
            Lamdera.sendToBackend Types.ClientInit

        Client.ResetProductions ->
            Lamdera.sendToBackend Types.ResetProductions

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

                Actor.FocusNameInput ->
                    Task.attempt FocusResult (Dom.focus "actorNameInput")

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

        Types.JoinedAsSpectator ->
            ( model, relayPlatformResponse JoinedAsSpectator )


subscriptions : a -> Sub Msg
subscriptions _ =
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


app : { init : Lamdera.Url -> Nav.Key -> ( Types.FrontendModel, Cmd Msg ), view : Types.FrontendModel -> Browser.Document Msg, update : Msg -> Types.FrontendModel -> ( Types.FrontendModel, Cmd Msg ), updateFromBackend : Types.ToFrontend -> Types.FrontendModel -> ( Types.FrontendModel, Cmd Msg ), subscriptions : Types.FrontendModel -> Sub Msg, onUrlRequest : UrlRequest -> Msg, onUrlChange : Url.Url -> Msg }
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
init _ key =
    ( { key = key
      , cueCannonModel = Client.initialModel
      }
    , Cmd.batch
        [ Lamdera.sendToBackend Types.ClientInit
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
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
