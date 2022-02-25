module Client exposing
    ( Model
    , Msg(..)
    , PlatformCmd(..)
    , PlatformResponse(..)
    , doNothing
    , initialModel
    , update
    , view
    )

import Actor
import Browser.Dom as Dom
import Director
import Html.Styled as Html exposing (..)
import Interface exposing (appScaffolding, debuggingPage, genericPage, loadingPage)
import List.Extra as List



--  ____  _       _    __
-- |  _ \| | __ _| |_ / _| ___  _ __ _ __ ___
-- | |_) | |/ _` | __| |_ / _ \| '__| '_ ` _ \
-- |  __/| | (_| | |_|  _| (_) | |  | | | | | |
-- |_|   |_|\__,_|\__|_|  \___/|_|  |_| |_| |_|
--
--     _             _     _ _            _
--    / \   _ __ ___| |__ (_) |_ ___  ___| |_ _   _ _ __ ___
--   / _ \ | '__/ __| '_ \| | __/ _ \/ __| __| | | | '__/ _ \
--  / ___ \| | | (__| | | | | ||  __/ (__| |_| |_| | | |  __/
-- /_/   \_\_|  \___|_| |_|_|\__\___|\___|\__|\__,_|_|  \___|
--
-- Our design extends/abuses the Elm Architecture to generalize
-- backends for our app. We call these "Platforms" in a nod to
-- the Roc Language. All platforms talk to our app through the
-- "PlatformCmd" and "PlatformResponse" types. We export view, update,
-- and init so the platform Elm App can add them to its own TEA.
--
-- Working platforms:
-- Lamdera
--
-- Planned platforms:
-- Libp2p / ionic
-- IHP (ionic?)
-- Tauri?


type alias Model =
    { menuOpen : Bool
    , state : State
    , logs : List String
    , viewLogs : Bool
    }


type State
    = InitialLoading
    | Testing Int
    | Spectating
    | Director Director.Model
    | Actor Actor.Model


type Msg
    = ToggleMenu
    | ToggleDebug
    | ActorMsg Actor.Msg
    | DirectorMsg Director.Msg
    | AdvanceInterfaceTestCase
    | OnlyPlatformResponse PlatformResponse
    | ClickedResetProductions
    | ClickedResetScripts
    | FocusResult (Result Dom.Error ())


type PlatformResponse
    = NoResponse
    | ReportErrors (List String)
    | JoinedAsSpectator
    | ActorPR Actor.PlatformResponse
    | DirectorPR Director.PlatformResponse


type PlatformCmd
    = NoCmd
    | ClientInit
    | ResetProductions
    | ResetScripts
    | ActorPC Actor.PlatformCmd
    | DirectorPC Director.PlatformCmd


initialModel : Model
initialModel =
    { menuOpen = False

    --, state = Testing 3
    -- To test, replace below with above
    , state = InitialLoading
    , logs = [ "Initial client log entry." ]
    , viewLogs = False
    }


update : Msg -> Model -> ( Model, PlatformCmd )
update msg model =
    let
        stateToModel state =
            { model | state = state }
    in
    case ( msg, model.state ) of
        ( ActorMsg subMsg, Actor subModel ) ->
            Actor.update subMsg subModel
                |> Tuple.mapFirst Actor
                |> Tuple.mapFirst stateToModel
                |> Tuple.mapSecond ActorPC

        ( DirectorMsg subMsg, Director subModel ) ->
            Director.update subMsg subModel
                |> Tuple.mapFirst Director
                |> Tuple.mapFirst stateToModel
                |> Tuple.mapSecond DirectorPC

        ( AdvanceInterfaceTestCase, Testing i ) ->
            let
                newIndex =
                    modBy (List.length interfaceTestCases) (i + 1)
            in
            ( Testing newIndex, NoCmd )
                |> Tuple.mapFirst stateToModel

        ( OnlyPlatformResponse _, Testing _ ) ->
            -- Ignore platform when testing
            ( model, NoCmd )

        ( OnlyPlatformResponse response, _ ) ->
            updateFromPlatform response model

        ( ToggleMenu, _ ) ->
            ( { model | menuOpen = not model.menuOpen }, NoCmd )

        ( ToggleDebug, _ ) ->
            ( { model | viewLogs = not model.viewLogs }, NoCmd )

        ( ClickedResetProductions, _ ) ->
            ( model, ResetProductions )

        ( ClickedResetScripts, _ ) ->
            ( model, ResetScripts )

        _ ->
            ( model, NoCmd )


updateFromPlatform : PlatformResponse -> Model -> ( Model, PlatformCmd )
updateFromPlatform response model =
    let
        stateToModel state =
            { model | state = state }
    in
    case ( response, model.state ) of
        -- Update
        ( ActorPR subResponse, Actor subModel ) ->
            Actor.updateFromPlatform subResponse subModel
                |> Tuple.mapFirst Actor
                |> Tuple.mapFirst stateToModel
                |> Tuple.mapSecond ActorPC

        ( DirectorPR subResponse, Director subModel ) ->
            Director.updateFromPlatform subResponse subModel
                |> Tuple.mapFirst Director
                |> Tuple.mapFirst stateToModel
                |> Tuple.mapSecond DirectorPC

        -- Transition
        ( ActorPR (Actor.StartCueing casting), Director (Director.ShowIsRunning script) ) ->
            Actor.updateFromPlatform (Actor.StartCueing casting)
                (Actor.Cueing
                    { script = script
                    , casting = casting
                    , lineNumber = 0
                    , name = "Director (you)"
                    }
                )
                |> Tuple.mapFirst Actor
                |> Tuple.mapFirst stateToModel
                |> Tuple.mapSecond ActorPC

        -- Init
        ( ActorPR subResponse, _ ) ->
            Actor.initialize subResponse
                |> Tuple.mapFirst Actor
                |> Tuple.mapFirst stateToModel
                |> Tuple.mapSecond ActorPC

        ( DirectorPR subResponse, _ ) ->
            Director.initialize subResponse
                |> Tuple.mapFirst Director
                |> Tuple.mapFirst stateToModel
                |> Tuple.mapSecond DirectorPC

        ( ReportErrors errors, _ ) ->
            ( { model | logs = errors }, NoCmd )

        ( JoinedAsSpectator, _ ) ->
            ( Spectating, NoCmd )
                |> Tuple.mapFirst stateToModel

        _ ->
            ( model, NoCmd )


type alias ModuleInjections msg =
    { menu : Html msg
    , menuOpen : Bool
    , toggleMsg : msg
    , resetProductionsMsg : msg
    , toggleDebugMsg : msg
    , resetScriptsMsg : msg
    }


view : Model -> Html Msg
view model =
    let
        ( config, currentPage ) =
            viewHelper Nothing model
    in
    appScaffolding config currentPage


viewHelper : Maybe Msg -> Model -> ( ModuleInjections Msg, Html Msg )
viewHelper testingMsg model =
    let
        config =
            { menu = Interface.header testingMsg
            , menuOpen = model.menuOpen
            , toggleMsg = ToggleMenu
            , resetProductionsMsg = ClickedResetProductions
            , toggleDebugMsg = ToggleDebug
            , resetScriptsMsg = ClickedResetScripts
            }
    in
    if model.viewLogs then
        ( config, debuggingPage (indexLogs model.logs) )

    else
        case model.state of
            Testing page ->
                List.getAt page interfaceTestCases
                    |> Maybe.withDefault model
                    |> viewHelper (Just AdvanceInterfaceTestCase)

            InitialLoading ->
                ( config, loadingPage )

            Spectating ->
                ( config, genericPage "Spectating (show in progress)" (Html.text "") )

            Director subModel ->
                ( config
                , Director.view subModel
                    |> Html.map DirectorMsg
                )

            Actor subModel ->
                ( config
                , Actor.view subModel
                    |> Html.map ActorMsg
                )


doNothing : a -> Msg
doNothing =
    always (OnlyPlatformResponse NoResponse)


indexLogs : List String -> List String
indexLogs logs =
    let
        len =
            List.length logs
    in
    List.indexedMap
        (\i log ->
            String.fromInt (len - i)
                ++ ": "
                ++ log
        )
        logs



--  ___       _             __
-- |_ _|_ __ | |_ ___ _ __ / _| __ _  ___ ___
--  | || '_ \| __/ _ \ '__| |_ / _` |/ __/ _ \
--  | || | | | ||  __/ |  |  _| (_| | (_|  __/
-- |___|_| |_|\__\___|_|  |_|  \__,_|\___\___|
--  _____         _      ____
-- |_   _|__  ___| |_   / ___|__ _ ___  ___  ___
--   | |/ _ \/ __| __| | |   / _` / __|/ _ \/ __|
--   | |  __/\__ \ |_  | |__| (_| \__ \  __/\__ \
--   |_|\___||___/\__|  \____\__,_|___/\___||___/
-- Interface Test Cases for states that need visual testing.


interfaceTestCases : List Model
interfaceTestCases =
    InitialLoading
        :: List.map Director Director.interfaceTestCases
        ++ List.map Actor Actor.interfaceTestCases
        |> List.map
            (\state ->
                { state = state
                , menuOpen = False
                , viewLogs = False
                , logs = []
                }
            )
