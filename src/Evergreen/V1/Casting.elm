module Evergreen.V1.Casting exposing (Actor, CastingChoices, Part)


type alias Actor =
    String


type alias Part =
    String


type alias CastingChoices =
    List
        { actors : List Actor
        , parts : List Part
        }
