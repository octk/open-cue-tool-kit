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
import Casting exposing (..)
import Dict exposing (Dict)
import Director
import Html.Styled as Html exposing (..)
import Interface exposing (appScaffolding, debuggingPage, loadingPage, tMenu)
import List.Extra as List
import TestScript exposing (testScript)



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


type Model
    = InitialLoading
    | Debugging (List String)
    | Testing Int
    | Spectating
    | Director Director.Model
    | Actor Actor.Model


type Msg
    = NoOp
    | ActorMsg Actor.Msg
    | DirectorMsg Director.Msg
    | AdvanceInterfaceTestCase
    | OnlyPlatformResponse PlatformResponse


type PlatformResponse
    = NoResponse
    | ReportErrors (List String)
    | ActorPR Actor.PlatformResponse
    | DirectorPR Director.PlatformResponse


type PlatformCmd
    = NoCmd
    | ClientInit
    | ActorPC Actor.PlatformCmd
    | DirectorPC Director.PlatformCmd


initialModel : Model
initialModel =
    -- initialModel = Testing 0
    -- To test, replace below with above
    InitialLoading


update : Msg -> Model -> ( Model, PlatformCmd )
update msg model =
    case ( msg, model ) of
        ( ActorMsg subMsg, Actor subModel ) ->
            Actor.update subMsg subModel
                |> Tuple.mapFirst Actor
                |> Tuple.mapSecond ActorPC

        ( DirectorMsg subMsg, Director subModel ) ->
            Director.update subMsg subModel
                |> Tuple.mapFirst Director
                |> Tuple.mapSecond DirectorPC

        ( AdvanceInterfaceTestCase, Testing i ) ->
            let
                newIndex =
                    modBy (List.length interfaceTestCases) (i + 1)
            in
            ( Testing newIndex, NoCmd )

        ( OnlyPlatformResponse response, m ) ->
            updateFromPlatform response m

        ( _, _ ) ->
            ( model, NoCmd )


updateFromPlatform : PlatformResponse -> Model -> ( Model, PlatformCmd )
updateFromPlatform response model =
    case ( response, model ) of
        -- Update
        ( ActorPR subResponse, Actor subModel ) ->
            Actor.updateFromPlatform subResponse subModel
                |> Tuple.mapFirst Actor
                |> Tuple.mapSecond ActorPC

        ( DirectorPR subResponse, Director subModel ) ->
            Director.updateFromPlatform subResponse subModel
                |> Tuple.mapFirst Director
                |> Tuple.mapSecond DirectorPC

        -- Init
        ( ActorPR subResponse, _ ) ->
            Actor.initialize subResponse
                |> Tuple.mapFirst Actor
                |> Tuple.mapSecond ActorPC

        ( DirectorPR subResponse, _ ) ->
            Director.initialize subResponse
                |> Tuple.mapFirst Director
                |> Tuple.mapSecond DirectorPC

        ( ReportErrors errors, _ ) ->
            ( Debugging errors, NoCmd )

        ( _, _ ) ->
            ( model, NoCmd )


view : Model -> Html Msg
view =
    viewHelper Nothing


viewHelper : Maybe Msg -> Model -> Html Msg
viewHelper testingMsg model =
    let
        currentPage =
            case model of
                Testing page ->
                    List.getAt page interfaceTestCases
                        |> Maybe.withDefault model
                        |> viewHelper (Just AdvanceInterfaceTestCase)

                InitialLoading ->
                    loadingPage

                Debugging errors ->
                    debuggingPage errors

                Spectating ->
                    Debug.todo "Add spectating page"

                Director subModel ->
                    Director.view subModel
                        |> Html.map DirectorMsg

                Actor subModel ->
                    Actor.view subModel
                        |> Html.map ActorMsg

        menu =
            tMenu testingMsg
    in
    appScaffolding menu currentPage


doNothing : a -> Msg
doNothing =
    always (OnlyPlatformResponse NoResponse)



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
    [ InitialLoading ]
        ++ List.map Director Director.interfaceTestCases
        ++ List.map Actor Actor.interfaceTestCases
