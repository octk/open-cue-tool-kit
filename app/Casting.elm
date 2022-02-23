--   ____          _   _
--  / ___|__ _ ___| |_(_)_ __   __ _
-- | |   / _` / __| __| | '_ \ / _` |
-- | |__| (_| \__ \ |_| | | | | (_| |
--  \____\__,_|___/\__|_|_| |_|\__, |
--                             |___/
-- Casting is complicated! We assume parts and actors have a
-- many-to-many relationship of casting choices. Either can be uncast.
-- Automatic casting might use line frequency, word counts, or
-- other metrics from the script to allocate parts.
-- I might switch to `CastingChoices = List { actor : Actor, part : Part }` if duplications get hard to manage. How to represent uncast parts though?
-- Better yet, I'll make a good API with a flexible datatype underneath.
-- Hmmm the datatype is hard to work with. I will make that change, and uncast parts are known by knowing the script + casting
-- Hmmm, after writing setActorToPart and adding all these tests, would [a + b + a*b] be better?


module Casting exposing (..)

import Dict exposing (Dict)
import List.Extra as List
import Set


type alias CastingChoices =
    List { actors : List Actor, parts : List Part }


type alias Actor =
    String


type alias Part =
    String


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


whichActorsPlayPart : Part -> CastingChoices -> List Actor
whichActorsPlayPart part casting =
    casting
        |> List.filter (\{ parts } -> List.member part parts)
        |> List.concatMap .actors


whichPartsAreActor : Actor -> CastingChoices -> List Part
whichPartsAreActor actor casting =
    casting
        |> List.filter (\{ actors } -> List.member actor actors)
        |> List.concatMap .parts


castParts : CastingChoices -> List Part
castParts casting =
    casting
        |> List.filter (\{ actors } -> not (List.isEmpty actors))
        |> List.concatMap .parts


uncastParts : CastingChoices -> List Part
uncastParts casting =
    casting
        |> List.filter (\{ actors } -> List.isEmpty actors)
        |> List.concatMap .parts
        |> Set.fromList
        |> Set.toList


uncastActors : CastingChoices -> List Actor
uncastActors casting =
    casting
        |> List.filter (\{ parts } -> List.isEmpty parts)
        |> List.concatMap .actors
        |> Set.fromList
        |> Set.toList


allActors : CastingChoices -> List Actor
allActors casting =
    List.concatMap .actors casting
        |> Set.fromList
        |> Set.toList


allParts : CastingChoices -> List Actor
allParts casting =
    List.concatMap .parts casting
        |> Set.fromList
        |> Set.toList


addActor : Actor -> CastingChoices -> CastingChoices
addActor actor casting =
    { actors = [ actor ], parts = [] } :: casting


setActorForPart : Actor -> Part -> CastingChoices -> CastingChoices
setActorForPart actor part casting =
    setActorsForPart [ actor ] part casting



{-
   Everyone else has the exact same parts.
-}


setActorsForPart : List Actor -> Part -> CastingChoices -> CastingChoices
setActorsForPart newActors partToSet casting =
    let
        allPartsSet : CastingChoices
        allPartsSet =
            Dict.insert partToSet newActors actorsByPart
                |> Dict.toList
                |> List.map (\( p, a ) -> { parts = [ p ], actors = a })

        allUncastActorsSet : CastingChoices
        allUncastActorsSet =
            uncastActors casting
                |> List.filter (\x -> List.notMember x newActors)
                |> (++) replacedActors
                |> List.map (\a -> { parts = [], actors = [ a ] })

        actorsByPart : Dict Part (List Actor)
        actorsByPart =
            casting
                |> List.concatMap castingChoiceToPairs
                |> List.foldl addActors emptyPartDict

        replacedActors =
            Dict.get partToSet actorsByPart
                |> Maybe.withDefault []

        castingChoiceToPairs choice =
            List.cartesianProduct [ choice.parts, choice.actors ]
                |> List.filterMap
                    (\pair ->
                        case pair of
                            part :: actor :: [] ->
                                Just ( part, actor )

                            _ ->
                                Nothing
                    )

        addActors ( p, actor ) partDict =
            Dict.update p (Maybe.map (addActorToPart actor)) partDict

        emptyPartDict =
            Dict.fromList (List.map (\p -> ( p, [] )) (allParts casting))

        addActorToPart newActor oldActors =
            newActor :: oldActors
    in
    allPartsSet ++ allUncastActorsSet


castByLineFrequency :
    List
        { a | speaker : String, line : String }
    -> List Actor
    -> CastingChoices
castByLineFrequency lines actors =
    let
        countsByPart =
            List.foldl countLines Dict.empty lines

        castPart ( part, lineCount ) castingChoices =
            List.minimumBy (getLineCount castingChoices) actors
                |> Maybe.map (\actor -> setActorForPart actor part castingChoices)
                |> Maybe.withDefault ({ parts = [ part ], actors = [] } :: castingChoices)

        getLineCount choices actor =
            whichPartsAreActor actor choices
                |> List.filterMap (\x -> Dict.get x countsByPart)
                |> List.sum

        countLinesHelper line =
            Maybe.map (\x -> Just (x + 1)) line
                |> Maybe.withDefault (Just 0)

        countLines { speaker } countsByPartSoFar =
            Dict.update speaker countLinesHelper countsByPartSoFar
    in
    Dict.toList countsByPart
        |> List.sortBy (\( _, charCount ) -> -charCount)
        |> List.foldl castPart []


makeEmptyCast :
    List
        { a | speaker : String, line : String }
    -> List Actor
    -> CastingChoices
makeEmptyCast lines actors =
    let
        partChoices =
            Set.fromList (List.map .speaker lines)
                |> Set.toList
                |> List.map (\part -> { actors = [], parts = [ part ] })

        actorChoices =
            List.map (\actor -> { actors = [ actor ], parts = [] }) actors
    in
    partChoices ++ actorChoices
