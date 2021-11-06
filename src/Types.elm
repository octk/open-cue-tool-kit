module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Casting exposing (CastingChoices)
import Client exposing (Model, Msg(..))
import Http
import Lamdera exposing (ClientId)
import Set
import Time
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , message : String
    , cueCannonModel : Model
    }


type alias BackendModel =
    { message : String
    , library : ScriptLibrary
    }


type alias Script =
    { title : String
    , lines :
        List
            { speaker : String
            , line : String
            , title : String
            , part : String
            }
    }


type ScriptLibrary
    = EmptyLibrary
    | Library { titles : List String, scripts : List Script }
    | Updating ClientId { notAdded : Set.Set String, added : Set.Set String, scripts : List Script }


type alias FrontendMsg =
    Msg


type ToBackend
    = FetchScripts
    | MakeInvitation Script
    | JoinProduction String String
    | ShareProduction CastingChoices
    | AdvanceCue


type BackendMsg
    = GotScriptList ClientId (Result Http.Error (List String))
    | FetchedScript String (Result Http.Error Script)
    | FetchScript String Time.Posix


type ToFrontend
    = LoadLibrary (List Script)
    | ConsiderInvite Script ClientId
    | ActorJoined String ClientId
    | StartCueing CastingChoices
    | IncrementLineNumber
