module Evergreen.V1.Types exposing (BackendModel, BackendMsg(..), FrontendModel, FrontendMsg, ScriptLibrary(..), ToBackend(..), ToFrontend(..))

import Browser.Navigation
import Evergreen.V1.Client
import Http
import Lamdera
import Set
import Time


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , message : String
    , cueCannonModel : Evergreen.V1.Client.Model
    }


type ScriptLibrary
    = EmptyLibrary
    | Library
        { titles : List String
        , scripts : List Evergreen.V1.Client.Script
        }
    | Updating
        Lamdera.ClientId
        { notAdded : Set.Set String
        , added : Set.Set String
        , scripts : List Evergreen.V1.Client.Script
        }


type alias BackendModel =
    { message : String
    , library : ScriptLibrary
    }


type alias FrontendMsg =
    Evergreen.V1.Client.Msg


type ToBackend
    = NoOpToBackend
    | FetchScripts


type BackendMsg
    = NoOpBackendMsg
    | GotScriptList Lamdera.ClientId (Result Http.Error (List String))
    | FetchedScript String (Result Http.Error Evergreen.V1.Client.Script)
    | FetchScript String Time.Posix


type ToFrontend
    = NoOpToFrontend
    | LoadLibrary (List Evergreen.V1.Client.Script)
