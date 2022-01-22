module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Casting exposing (CastingChoices)
import Client exposing (Model, Msg(..))
import Dict exposing (Dict)
import Http
import Lamdera exposing (ClientId)
import Set
import Time
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , cueCannonModel : Model
    }


type alias BackendModel =
    { library : State
    , errorCount : Dict String Int
    , errorLog : List String
    , staleTimer : Timer
    }


type Timer
    = TimerSet Time.Posix
    | TimerNotSet


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


type State
    = EmptyLibrary
    | FullLibrary { titles : List String, scripts : List Script, productions : Dict String Production }
    | Updating
        ClientId
        { notAdded : Set.Set String
        , added : Set.Set String
        , scripts : List Script
        , fetching : Bool
        }


type alias Production =
    { directorId : String
    , status : ProductionStatus
    , script : Script
    , casting : CastingChoices
    , namesBySessionId : Dict String String
    }


type alias ProductionStatus =
    Int


type alias FrontendMsg =
    Msg


type ToBackend
    = ClientInit
    | MakeInvitation Script
    | JoinProduction String String
    | ShareProduction CastingChoices
    | AdvanceCue


type BackendMsg
    = GotScriptList ClientId (Result Http.Error (List String))
    | FetchedScript String (Result Http.Error Script)
    | FetchScript String Time.Posix
    | SettingTimer Time.Posix
    | CheckTimer Time.Posix


type
    ToFrontend
    -- My approach has been to not share state on every msg,
    -- instead having messages for everything that can change.
    -- The case of someone recovering from disconnection motivates
    -- a "share-everything" msg too. Maybe I switch to a share-everything
    -- model, with many optional fields, counting on lamedera's
    -- write compression to make it light? That will reduce
    -- the risk of two endpoints disagreeing how to set state.
    = LoadLibrary (List Script)
    | ConsiderInvite Script ClientId
    | ActorJoined String ClientId
    | StartCueing CastingChoices
    | IncrementLineNumber
    | ReportErrors (List String)
    | SetState { script : Script, name : String, casting : CastingChoices, lineNumber : Int }
