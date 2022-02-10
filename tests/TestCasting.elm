module Example exposing (..)

import Casting
    exposing
        ( allActors
        , allParts
        , castByLineFrequency
        , makeEmptyCast
        , setActorForPart
        , uncastActors
        , uncastParts
        , whichActorsPlayPart
        )
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "The casting module" <|
        [ describe "Setting actors to parts" <|
            [ test "Setting an actor works" <|
                \_ ->
                    let
                        setting =
                            setActorForPart "Tom" "Hamlet" []
                                |> whichActorsPlayPart "Hamlet"
                    in
                    Expect.equal setting [ "Tom" ]
            , test "Setting actor unsets previous actor from part" <|
                \_ ->
                    let
                        setting =
                            setActorForPart "Tom" "Hamlet" []
                                |> setActorForPart "Jerry" "Hamlet"
                                |> whichActorsPlayPart "Hamlet"
                    in
                    Expect.equal setting [ "Jerry" ]
            , test "Setting multiple actors keeps all actors" <|
                \_ ->
                    let
                        setting =
                            setActorForPart "Tom" "Hamlet" []
                                |> setActorForPart "Jerry" "Ophelia"
                                |> setActorForPart "The Dog" "Laertes"
                                |> allActors
                                |> List.sort
                    in
                    Expect.equal setting (List.sort [ "Tom", "Jerry", "The Dog" ])
            , test "Setting multiple actors keeps all parts" <|
                \_ ->
                    let
                        setting =
                            setActorForPart "Tom" "Hamlet" []
                                |> setActorForPart "Jerry" "Ophelia"
                                |> setActorForPart "The Dog" "Laertes"
                                |> allParts
                                |> List.sort
                    in
                    Expect.equal setting (List.sort [ "Hamlet", "Ophelia", "Laertes" ])
            , test "Setting to manual cast keeps actors" <|
                \_ ->
                    let
                        lines =
                            [ { speaker = "Tom", line = "I am a cat" }
                            , { speaker = "Jerry", line = "Shhh" }
                            ]

                        actors =
                            [ "Chris", "Roger", "Steve" ]

                        setting =
                            makeEmptyCast lines actors
                                |> setActorForPart "Chris" "Tom"
                    in
                    Expect.equal (List.sort actors) (List.sort (allActors setting))
            , test "Overwriting set to manual cast keeps actors" <|
                \_ ->
                    let
                        lines =
                            [ { speaker = "Tom", line = "I am a cat" }
                            , { speaker = "Jerry", line = "Shhh" }
                            ]

                        actors =
                            [ "Chris", "Roger", "Steve" ]

                        setting =
                            makeEmptyCast lines actors
                                |> setActorForPart "Chris" "Tom"
                                |> setActorForPart "Roger" "Tom"
                    in
                    Expect.equal (List.sort actors) (List.sort (allActors setting))
            , test "Setting to manual cast keeps parts" <|
                \_ ->
                    let
                        lines =
                            [ { speaker = "Tom", line = "I am a cat" }
                            , { speaker = "Jerry", line = "Shhh" }
                            ]

                        actors =
                            [ "Chris", "Roger", "Steve" ]

                        setting =
                            makeEmptyCast lines actors
                                |> setActorForPart "Chris" "Tom"
                    in
                    Expect.equal (List.sort [ "Tom", "Jerry" ]) (List.sort (allParts setting))
            , test "Multiple sets does not duplicate actors" <|
                \_ ->
                    let
                        lines =
                            [ { speaker = "Tom", line = "I am a cat" }
                            , { speaker = "Jerry", line = "Shhh" }
                            ]

                        actors =
                            [ "Chris", "Roger", "Steve" ]

                        setting =
                            makeEmptyCast lines actors
                                |> setActorForPart "Chris" "Tom"
                                |> setActorForPart "Chris" "Jerry"
                    in
                    Expect.equal (List.length (allActors setting)) 3
            , test "Multiple sets does not duplicate roles" <|
                \_ ->
                    let
                        lines =
                            [ { speaker = "Tom", line = "I am a cat" }
                            , { speaker = "Jerry", line = "Shhh" }
                            ]

                        actors =
                            [ "Chris", "Roger", "Steve" ]

                        setting =
                            makeEmptyCast lines actors
                                |> setActorForPart "Chris" "Tom"
                                |> setActorForPart "Roger" "Tom"
                    in
                    Expect.equal (List.length (allParts setting)) 2
            ]
        , describe "Casting" <|
            [ test "Casting without lines is empty" <|
                \_ -> Expect.equal [] (castByLineFrequency [] [ "Tom" ])
            , test "Casting without actors is not empty" <|
                \_ ->
                    let
                        lines =
                            [ { speaker = "Tom", line = "I am a cat" } ]
                    in
                    Expect.notEqual [] (castByLineFrequency lines [])
            , test "Casting with empty actors still sets parts" <|
                \_ ->
                    let
                        actors =
                            []

                        lines =
                            [ { speaker = "Tom", line = "I am a cat" } ]

                        cast =
                            castByLineFrequency lines actors
                    in
                    Expect.equal cast [ { parts = [ "Tom" ], actors = [] } ]
            ]
        , describe "Finding uncast " <|
            [ test "Uncast parts accurate" <|
                \_ ->
                    let
                        actors =
                            []

                        lines =
                            [ { speaker = "Tom", line = "I am a cat" }
                            , { speaker = "Jerry", line = "Shhh" }
                            ]

                        uncast =
                            uncastParts (castByLineFrequency lines actors)
                    in
                    Expect.equal (List.sort uncast) (List.sort [ "Tom", "Jerry" ])
            , test "Uncast actors accurate" <|
                \_ ->
                    let
                        casting =
                            [ { actors = [ "Tom" ], parts = [] }, { actors = [ "Jerry" ], parts = [ "Hamlet" ] } ]

                        uncast =
                            uncastActors casting
                    in
                    Expect.equal uncast [ "Tom" ]
            ]
        ]
