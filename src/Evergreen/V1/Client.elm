module Evergreen.V1.Client exposing (Actor, CueingAction(..), Intention(..), ManualChoice(..), Model, Msg(..), Part, PlatformResponse(..), Script(..))

import Evergreen.V1.Casting


type CueingAction
    = Listening
        { speaker : String
        , nextParts : List String
        }
    | Speaking
        { line : String
        , character : String
        }


type Script
    = Script
        String
        (List
            { speaker : String
            , line : String
            , title : String
            , part : String
            }
        )


type alias Actor =
    String


type alias Part =
    String


type ManualChoice
    = PartFor Actor
    | ActorFor Part


type Intention
    = Cueing CueingAction
    | Casting
        { casting : Evergreen.V1.Casting.CastingChoices
        , invitationLink : String
        , script : Script
        , manualCasting : Maybe ManualChoice
        }
    | Browsing (List Script)
    | Accepting
        { title : String
        , director : String
        }
    | Loading


type alias Model =
    { name : String
    , intent : Intention
    , autocast : Bool
    }


type PlatformResponse
    = NoResponse
    | AddScripts (List Script)


type Msg
    = NoOp
    | ChangeName String
    | OnlyPlatformResponse PlatformResponse
    | PickScript Script
    | ToggleAutocast
    | MakeManualCastingChoice ManualChoice
    | CastActorAsPart Actor Part
    | CancelModal
