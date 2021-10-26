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

import Casting exposing (..)
import Css
import Css.Global
import Dict exposing (Dict)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events exposing (onClick)
import List.Extra as List
import QRCode
import Svg.Attributes as SvgA
import Svg.Styled as Svg exposing (path, svg)
import Svg.Styled.Attributes as SvgAttr
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw exposing (..)



--  _____ _            _____ _
-- |_   _| |__   ___  | ____| |_ __ ___
--   | | | '_ \ / _ \ |  _| | | '_ ` _ \
--   | | | | | |  __/ | |___| | | | | | |
--   |_| |_| |_|\___| |_____|_|_| |_| |_|
--
--     _             _     _ _            _
--    / \   _ __ ___| |__ (_) |_ ___  ___| |_ _   _ _ __ ___
--   / _ \ | '__/ __| '_ \| | __/ _ \/ __| __| | | | '__/ _ \
--  / ___ \| | | (__| | | | | ||  __/ (__| |_| |_| | | |  __/
-- /_/   \_\_|  \___|_| |_|_|\__\___|\___|\__|\__,_|_|  \___|
-- The Elm Architecture describes the business of the app


type alias Model =
    { selectedIntentionTestCase : Maybe Int
    , name : String
    , intent : Intention
    , autocast : Bool
    , host : Maybe String
    }


initialModel : Model
initialModel =
    { selectedIntentionTestCase = Nothing
    , name = ""
    , intent = Loading
    , autocast = True
    , host = Nothing
    }


type Msg
    = -- App
      NoOp
    | AcceptInvitation
    | ChangeName String
    | CancelModal
    | OnlyPlatformResponse PlatformResponse
    | CueNextActor
      -- Director
    | PickScript Script
    | ToggleAutocast
    | ConsiderCastingChoice ManualChoice
    | CastActorAsPart Actor Part
    | BeginShow
      -- Debug
    | AdvanceIntentionTestCase


type PlatformResponse
    = NoResponse
    | AddScripts (List Script)
    | ConsiderInvite Script String
    | ActorJoined String String
    | StartCueing CastingChoices
    | IncrementLineNumber
    | ReportErrors (List String)
    | SetHost String


type PlatformCmd
    = NoCmd
    | FetchScripts
    | MakeInvitation Script
    | JoinProduction String String
    | ShareProduction CastingChoices
    | AdvanceCue


update : Msg -> Model -> ( Model, PlatformCmd )
update msg model =
    case msg of
        -- App
        NoOp ->
            ( model, NoCmd )

        AcceptInvitation ->
            acceptInvitationHelper model

        ChangeName newName ->
            ( { model | name = newName }, NoCmd )

        CancelModal ->
            ( { model | intent = mapCasting cancelModalHelper model.intent }, NoCmd )

        OnlyPlatformResponse response ->
            updateFromPlatform response model

        CueNextActor ->
            ( model, AdvanceCue )

        -- Director
        PickScript { title, lines } ->
            pickScriptHelper model title lines

        ToggleAutocast ->
            ( toggleAutocastHelper model, NoCmd )

        ConsiderCastingChoice choice ->
            ( { model | intent = mapCasting (considerCastingChoiceHelper choice) model.intent }, NoCmd )

        CastActorAsPart actor part ->
            castHelper actor part model

        BeginShow ->
            beginShowHelper model

        -- Debug
        AdvanceIntentionTestCase ->
            let
                l =
                    List.length intentionTestCases

                newIndex =
                    case model.selectedIntentionTestCase of
                        Nothing ->
                            0

                        Just i ->
                            modBy l (i + 1)
            in
            ( { model | selectedIntentionTestCase = Just newIndex }, NoCmd )


updateFromPlatform : PlatformResponse -> Model -> ( Model, PlatformCmd )
updateFromPlatform response model =
    case response of
        -- App
        NoResponse ->
            ( model, NoCmd )

        ConsiderInvite script clientId ->
            case model.intent of
                Browsing _ ->
                    ( { model
                        | intent =
                            Accepting { script = script, director = "Director ", directorId = clientId, joining = False }
                      }
                    , NoCmd
                    )

                _ ->
                    ( model, NoCmd )

        StartCueing casting ->
            case model.intent of
                Accepting { script } ->
                    ( { model | intent = Cueing { script = script, casting = casting, lineNumber = 0 } }, NoCmd )

                _ ->
                    ( model, NoCmd )

        AddScripts scripts ->
            ( { model
                | intent =
                    Browsing scripts
              }
            , NoCmd
            )

        IncrementLineNumber ->
            incrementLineNumberHelper model

        SetHost host ->
            ( { model | host = Just host }, NoCmd )

        -- Director
        ActorJoined name actorClientId ->
            ( { model | intent = mapCasting (actorJoinedHelper model name actorClientId) model.intent }, NoCmd )

        ReportErrors errors ->
            ( { model | intent = ReportingErrors errors }, NoCmd )


pickScriptHelper :
    Model
    -> String
    -> List { line : String, part : String, speaker : String, title : String }
    -> ( Model, PlatformCmd )
pickScriptHelper model title lines =
    let
        script =
            Script title lines
    in
    ( { model
        | intent =
            Casting
                { casting = makeEmptyCast lines []
                , manualCasting = Nothing
                , script = script
                }
      }
    , MakeInvitation script
    )


considerCastingChoiceHelper : ManualChoice -> CastingDetails -> CastingDetails
considerCastingChoiceHelper choice details =
    { details | manualCasting = Just choice }


cancelModalHelper : CastingDetails -> CastingDetails
cancelModalHelper details =
    { details | manualCasting = Nothing }


castHelper : Actor -> Part -> Model -> ( Model, PlatformCmd )
castHelper actor part model =
    let
        cast details =
            { details
                | casting = setActorForPart actor part details.casting
                , manualCasting = Nothing
            }
    in
    ( { model | intent = mapCasting cast model.intent }, NoCmd )


acceptInvitationHelper : Model -> ( Model, PlatformCmd )
acceptInvitationHelper model =
    let
        addJoining details =
            { details | joining = True }
    in
    case model.intent of
        Accepting ({ directorId } as details) ->
            ( { model | intent = Accepting (addJoining details) }, JoinProduction model.name directorId )

        _ ->
            ( model, NoCmd )


incrementLineNumberHelper model =
    let
        newIntent =
            case model.intent of
                Cueing ({ lineNumber } as details) ->
                    Cueing { details | lineNumber = lineNumber + 1 }

                _ ->
                    model.intent
    in
    ( { model | intent = newIntent }, NoCmd )


actorJoinedHelper : Model -> String -> String -> CastingDetails -> CastingDetails
actorJoinedHelper model name actorClientId details =
    let
        currentActors =
            allActors details.casting

        newActor =
            if List.member name currentActors then
                name
                -- ++ " " ++ actorClientId -- FIXME Actors need to know own client ids prevent collisions

            else
                name
    in
    { details
        | casting =
            if model.autocast then
                castByLineFrequency details.script.lines (newActor :: currentActors)

            else
                addActor newActor details.casting
    }


beginShowHelper : Model -> ( Model, PlatformCmd )
beginShowHelper model =
    case model.intent of
        Casting { casting } ->
            ( model, ShareProduction casting )

        _ ->
            ( model, NoCmd )


toggleAutocastHelper model =
    let
        auto =
            not model.autocast

        recast ({ casting, script } as details) =
            { details
                | casting =
                    if model.autocast then
                        castByLineFrequency script.lines (allActors casting)

                    else
                        casting
            }
    in
    { model | autocast = auto, intent = mapCasting recast model.intent }


view : Model -> Html Msg
view model =
    appTemplate (applyIntentionTestCase model)


applyIntentionTestCase : Model -> Model
applyIntentionTestCase model =
    case model.selectedIntentionTestCase of
        Nothing ->
            model

        Just i ->
            { model
                | intent =
                    List.getAt i intentionTestCases
                        |> Maybe.withDefault Loading
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


type Intention
    = Cueing { script : Script, casting : CastingChoices, lineNumber : Int }
    | Casting CastingDetails
    | Browsing (List Script)
    | Accepting { script : Script, director : String, directorId : String, joining : Bool }
    | Loading
    | ReportingErrors (List String)


makeCueingAction : String -> { script : Script, casting : CastingChoices, lineNumber : Int } -> CueingAction
makeCueingAction name { script, casting, lineNumber } =
    let
        myParts =
            whichPartsAreActor name casting

        currentLine =
            List.getAt lineNumber script.lines

        nextParts =
            List.map .speaker script.lines
                |> List.filter (\speaker -> List.notMember speaker myParts)
                |> List.unique
    in
    case currentLine of
        Nothing ->
            ShowOver

        Just { line, speaker } ->
            if List.member speaker myParts then
                Speaking { line = line, character = speaker }

            else
                Listening { speaker = speaker, nextParts = nextParts }


type alias CastingDetails =
    { casting : Casting.CastingChoices
    , script : Script
    , manualCasting : Maybe ManualChoice
    }


mapCasting : (CastingDetails -> CastingDetails) -> Intention -> Intention
mapCasting f intention =
    case intention of
        Casting details ->
            Casting (f details)

        other ->
            other


type CueingAction
    = Listening { speaker : String, nextParts : List String }
    | Speaking { line : String, character : String }
    | ShowOver


type ManualChoice
    = PartFor Actor
    | ActorFor Part


type alias Actor =
    String


type alias Part =
    String


doNothing =
    always (OnlyPlatformResponse NoResponse)



--     _                  _____                    _       _
--    / \   _ __  _ __   |_   _|__ _ __ ___  _ __ | | __ _| |_ ___
--   / _ \ | '_ \| '_ \    | |/ _ \ '_ ` _ \| '_ \| |/ _` | __/ _ \
--  / ___ \| |_) | |_) |   | |  __/ | | | | | |_) | | (_| | ||  __/
-- /_/   \_\ .__/| .__/    |_|\___|_| |_| |_| .__/|_|\__,_|\__\___|
--         |_|   |_|                        |_|
-- App Template specifies all of the ui choices in tailwind and html


appTemplate model =
    let
        title =
            case model.intent of
                Cueing cueDetails ->
                    case makeCueingAction model.name cueDetails of
                        ShowOver ->
                            "The End"

                        Listening _ ->
                            "Listening"

                        Speaking _ ->
                            "Speaking"

                Casting { script } ->
                    script.title

                Browsing scripts ->
                    "Select a script"

                Accepting _ ->
                    "Joining production"

                Loading ->
                    ""

                ReportingErrors _ ->
                    "Reporting Errors"
    in
    div
        []
        [ Css.Global.global globalStyles
        , div
            [ css
                [ h_screen
                , w_screen
                , bg_white
                , flex
                , flex_col
                , justify_end
                ]
            ]
            [ nav [ css [ bg_white, border_b, border_gray_200 ] ]
                [ div
                    [ css
                        [ max_w_7xl
                        , mx_auto
                        , px_4
                        , Bp.lg [ px_8 ]
                        , Bp.sm [ px_6 ]
                        ]
                    ]
                    [ div [ css [ flex, justify_between, h_16 ] ]
                        [ tMenu title
                        , div
                            [ css
                                [ hidden, Bp.sm [ ml_6, flex, items_center ] ]
                            ]
                            [ case model.selectedIntentionTestCase of
                                Just _ ->
                                    intentionTestCaseSelector

                                _ ->
                                    emptyTemplate
                            ]
                        ]
                    ]
                ]
            , div [ css [ h_full ] ]
                [ case model.intent of
                    Cueing cueDetails ->
                        cueingPage (makeCueingAction model.name cueDetails)

                    Casting cast ->
                        castingPage cast model.autocast model.host

                    Browsing scripts ->
                        browsingPage scripts

                    Accepting { script, director, joining } ->
                        acceptingPage script director joining model.name

                    Loading ->
                        loadingPage

                    ReportingErrors errors ->
                        reportingErrorsPage errors
                ]
            ]
        ]



--  ____
-- |  _ \ __ _  __ _  ___  ___
-- | |_) / _` |/ _` |/ _ \/ __|
-- |  __/ (_| | (_| |  __/\__ \
-- |_|   \__,_|\__, |\___||___/
--             |___/
-- Pages are the views that correspond to the user's intentions
-- TODO Make an elm-review rule that formats these long css lists more nicely.
-- TODO Subdivide scripts so one can select just an act or scene


loadingPage =
    div [ css [ Tw.bg_white ] ]
        [ div
            [ css
                [ Tw.max_w_7xl
                , Tw.mx_auto
                , Tw.py_16
                , Tw.px_4
                , Bp.lg [ Tw.px_8 ]
                , Bp.sm [ Tw.py_24, Tw.px_6 ]
                ]
            ]
            [ div [ css [ Tw.text_center ] ]
                [ h2
                    [ css
                        [ Tw.text_base
                        , Tw.font_semibold
                        , Tw.text_indigo_600
                        , Tw.tracking_wide
                        , Tw.uppercase
                        ]
                    ]
                    [ text "Loading" ]
                ]
            ]
        ]


reportingErrorsPage errors =
    div [ css [ Tw.bg_white ] ]
        [ div
            [ css
                [ Tw.max_w_7xl
                , Tw.mx_auto
                , Tw.py_16
                , Tw.px_4
                , Bp.lg [ Tw.px_8 ]
                , Bp.sm [ Tw.py_24, Tw.px_6 ]
                ]
            ]
            [ div [ css [ Tw.text_center ] ]
                [ h2
                    [ css
                        [ Tw.text_base
                        , Tw.font_semibold
                        , Tw.text_indigo_600
                        , Tw.tracking_wide
                        , Tw.uppercase
                        ]
                    ]
                    [ text "Errors encountered" ]
                , pre [] [ text (String.join "\n" errors) ]
                ]
            ]
        ]


browsingPage scripts =
    ul
        [ Attr.attribute "role" "list", css [ Tw.divide_y, Tw.divide_gray_200 ] ]
        (List.map
            (\({ title } as script) ->
                li [ css [ Tw.py_4, Tw.flex, Tw.truncate ] ]
                    [ div [ css [ Tw.ml_3 ] ]
                        [ p
                            [ css
                                [ Tw.text_sm
                                , Tw.font_medium
                                , Tw.text_gray_900
                                ]
                            , Events.onClick (PickScript script)
                            ]
                            [ text title ]
                        ]
                    ]
            )
            scripts
        )


alreadyCastPartsAndActors autocast casting =
    castParts casting
        |> List.map
            (\part ->
                ( part
                , String.join " "
                    (whichActorsPlayPart
                        part
                        casting
                    )
                )
            )
        |> List.map
            (\( part, actor ) ->
                li
                    ([ css [ bg_white ]
                     ]
                        ++ (if autocast then
                                []

                            else
                                [ onClick (ConsiderCastingChoice (ActorFor part)) ]
                           )
                    )
                    [ a
                        [ Attr.href "#"
                        , css [ block, Css.hover [ bg_gray_50 ] ]
                        ]
                        [ div [ css [ px_4, py_4, Bp.sm [ px_6 ] ] ]
                            [ div
                                [ css
                                    [ flex
                                    , items_center
                                    , justify_between
                                    ]
                                ]
                                [ p
                                    [ css
                                        [ text_sm
                                        , font_medium
                                        , text_indigo_600
                                        , Tw.truncate
                                        ]
                                    ]
                                    [ text part ]
                                , div
                                    [ css
                                        [ ml_2
                                        , flex_shrink_0
                                        , flex
                                        ]
                                    ]
                                    [ p
                                        [ css
                                            [ text_sm
                                            , font_medium
                                            , text_indigo_600
                                            , Tw.truncate
                                            ]
                                        ]
                                        [ text actor ]
                                    ]
                                ]
                            ]
                        ]
                    ]
            )


yetUncastActors autocast casting =
    uncastActors casting
        |> List.map
            (\actor ->
                li
                    ([ css [ bg_white ]
                     ]
                        ++ (if autocast then
                                []

                            else
                                [ onClick (ConsiderCastingChoice (PartFor actor)) ]
                           )
                    )
                    [ a
                        [ Attr.href "#"
                        , css [ block, Css.hover [ bg_gray_50 ] ]
                        ]
                        [ div [ css [ px_4, py_4, Bp.sm [ px_6 ] ] ]
                            [ div
                                [ css
                                    [ flex
                                    , items_center
                                    , justify_between
                                    ]
                                ]
                                [ p
                                    [ css
                                        [ px_2
                                        , inline_flex
                                        , text_xs
                                        , leading_5
                                        , font_semibold
                                        , rounded_full
                                        , bg_green_100
                                        , text_green_800
                                        ]
                                    ]
                                    [ text "(uncast)" ]
                                , div
                                    [ css
                                        [ ml_2
                                        , flex_shrink_0
                                        , flex
                                        ]
                                    ]
                                    [ p
                                        [ css
                                            [ px_2
                                            , inline_flex
                                            , text_xs
                                            , leading_5
                                            , font_semibold
                                            , rounded_full
                                            , bg_green_100
                                            , text_green_800
                                            ]
                                        ]
                                        [ text actor ]
                                    ]
                                ]
                            ]
                        ]
                    ]
            )


yetUncastParts autocast casting =
    uncastParts casting
        |> List.map
            (\part ->
                li
                    ([ css [ bg_white ]
                     ]
                        ++ (if autocast then
                                []

                            else
                                [ onClick (ConsiderCastingChoice (ActorFor part)) ]
                           )
                    )
                    [ a
                        [ Attr.href "#"
                        , css [ block, Css.hover [ bg_gray_50 ] ]
                        ]
                        [ div [ css [ px_4, py_4, Bp.sm [ px_6 ] ] ]
                            [ div
                                [ css
                                    [ flex
                                    , items_center
                                    , justify_between
                                    ]
                                ]
                                [ p
                                    [ css
                                        [ px_2
                                        , inline_flex
                                        , text_xs
                                        , leading_5
                                        , font_semibold
                                        , rounded_full
                                        , bg_green_100
                                        , text_green_800
                                        ]
                                    ]
                                    [ text part ]
                                , div
                                    [ css
                                        [ ml_2
                                        , flex_shrink_0
                                        , flex
                                        ]
                                    ]
                                    [ p
                                        [ css
                                            [ px_2
                                            , inline_flex
                                            , text_xs
                                            , leading_5
                                            , font_semibold
                                            , rounded_full
                                            , bg_green_100
                                            , text_green_800
                                            ]
                                        ]
                                        [ text "(uncast)" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
            )


castingSwitch autocast =
    [ li
        [ css
            [ p_4
            , flex
            , items_center
            , justify_between
            , bg_white
            ]
        ]
        [ div
            [ css
                [ flex
                , flex_col
                ]
            ]
            [ p
                [ css
                    [ text_sm
                    , font_medium
                    , text_gray_900
                    ]
                ]
                [ text
                    ("Cast automatically: "
                        ++ (if autocast then
                                "on"

                            else
                                "off"
                           )
                    )
                ]
            , p
                [ css
                    [ text_sm
                    , text_gray_500
                    ]
                ]
                [ if autocast then
                    text "Actors are randomly assigned parts balanced by their number of lines"

                  else
                    text "You decide which parts are played by which actors"
                ]
            ]
        , button
            [ Attr.type_ "button"
            , onClick ToggleAutocast
            , css
                [ ml_4
                , relative
                , inline_flex
                , flex_shrink_0
                , h_6
                , w_11
                , border_2
                , border_transparent
                , rounded_full
                , cursor_pointer
                , transition_colors
                , ease_in_out
                , duration_200
                , Css.focus
                    [ outline_none
                    , ring_2
                    , ring_offset_2
                    ]

                -- Order matters for elm-tailwind, so dynamic last
                , if autocast then
                    bg_gray_200

                  else
                    bg_gray_500
                ]
            , Attr.attribute "role" "switch"
            , Attr.attribute "aria-checked" "true"
            , Attr.attribute "aria-labelledby" "privacy-option-1-label"
            , Attr.attribute "aria-describedby" "privacy-option-1-description"
            ]
            [ span
                [ Attr.attribute "aria-hidden" "true"
                , css
                    [ inline_block
                    , h_5
                    , w_5
                    , rounded_full
                    , bg_white
                    , shadow
                    , transform
                    , ring_0
                    , transition
                    , ease_in_out
                    , duration_200

                    -- Order matters for elm-tailwind, so dynamic last
                    , if autocast then
                        translate_x_0

                      else
                        translate_x_5
                    ]
                ]
                []
            ]
        ]
    ]


castingPage { casting, manualCasting } autocast host =
    let
        actorsPresent =
            not (List.isEmpty (allActors casting))

        showIsCast =
            List.isEmpty (uncastParts casting)
    in
    div
        [ css
            [ bg_gray_50
            , shadow
            , overflow_hidden
            , h_full
            , Bp.sm
                [ rounded_md
                ]
            ]
        ]
        [ div [ css [ flex, flex_col, h_full ] ]
            [ div []
                [ div
                    [ css
                        [ flex
                        , items_center
                        , justify_center
                        , bg_gray_50
                        , py_12
                        , px_4
                        , Bp.lg [ px_8 ]
                        , Bp.sm [ px_6 ]
                        ]
                    ]
                    [ div [ css [ max_w_md ] ]
                        [ div [ css [ flex, justify_center ] ]
                            (case host of
                                Just hostUrl ->
                                    [ QRCode.fromString hostUrl
                                        |> Result.map
                                            (QRCode.toSvg [ SvgA.width "150px", SvgA.height "150px" ]
                                                >> fromUnstyled
                                            )
                                        |> Result.withDefault (text "Error while encoding to QRCode.")
                                    ]

                                Nothing ->
                                    []
                            )
                        , div []
                            [ button
                                [ Attr.type_ "submit"
                                , css
                                    [ relative
                                    , w_full
                                    , flex
                                    , justify_center
                                    , py_2
                                    , px_4
                                    , border
                                    , border_transparent
                                    , text_sm
                                    , font_medium
                                    , rounded_md
                                    , text_white
                                    , bg_indigo_600
                                    , Css.focus
                                        [ outline_none
                                        , ring_2
                                        , ring_offset_2
                                        , ring_indigo_500
                                        ]
                                    , Css.hover [ bg_indigo_700 ]
                                    ]
                                ]
                                [ text "Copy invitation link" ]
                            ]
                        ]
                    ]
                ]
            , ul
                [ Attr.attribute "role" "list"
                , css [ divide_y, divide_gray_200, overflow_scroll ]
                ]
                (castingSwitch autocast
                    ++ (if actorsPresent then
                            yetUncastActors autocast casting
                                ++ yetUncastParts autocast casting
                                ++ alreadyCastPartsAndActors autocast casting

                        else
                            [ li
                                [ css [ p_4 ] ]
                                [ text "Waiting for actors..." ]
                            ]
                       )
                )
            , div [ css [ mb_8, bg_gray_50, mt_auto ] ]
                (if showIsCast then
                    [ button
                        [ Attr.type_ "submit"
                        , css
                            [ relative
                            , w_full
                            , flex
                            , justify_center
                            , py_2
                            , px_4
                            , border
                            , border_transparent
                            , text_sm
                            , font_medium
                            , rounded_md
                            , text_white
                            , bg_indigo_600
                            , Css.focus
                                [ outline_none
                                , ring_2
                                , ring_offset_2
                                , ring_indigo_500
                                ]
                            , Css.hover [ bg_indigo_700 ]
                            ]
                        , onClick BeginShow
                        ]
                        [ text "Begin Show" ]
                    ]

                 else
                    []
                )
            ]
        , case manualCasting of
            Just choice ->
                castingModal casting choice

            Nothing ->
                emptyTemplate
        ]


acceptingPage : Script -> String -> Bool -> String -> Html Msg
acceptingPage { title } director joining name =
    div
        [ css
            [ h_full ]
        ]
        [ div
            [ css
                [ max_w_7xl
                , mx_auto
                , flex
                , flex_col
                , h_full
                , Bp.lg [ px_8 ]
                , Bp.sm [ px_6 ]
                ]
            ]
            [ header []
                [ div
                    [ css
                        [ max_w_7xl
                        , mx_auto
                        , px_4
                        , Bp.lg [ px_8 ]
                        , Bp.sm [ px_6 ]
                        ]
                    ]
                    [ h1
                        [ css
                            [ text_3xl
                            , font_bold
                            , leading_tight
                            , text_gray_900
                            ]
                        ]
                        [ text
                            ("Join a production of "
                                ++ String.replace ".json" "" (String.replace "_" " " title)
                                ++ "?"
                            )
                        ]
                    ]
                ]
            , div
                [ css [ mx_4, mt_4 ] ]
                [ label
                    [ css
                        [ Tw.block
                        , Tw.text_sm
                        , Tw.font_medium
                        , Tw.text_gray_700
                        ]
                    ]
                    [ text "What's your name?" ]
                , div [ css [ Tw.mt_1 ] ]
                    [ input
                        [ Attr.type_ "text"
                        , Events.onInput ChangeName
                        , css
                            [ Tw.shadow_sm
                            , Tw.block
                            , Tw.w_full
                            , Tw.border_gray_300
                            , Tw.rounded_md
                            , Css.focus
                                [ Tw.ring_indigo_500
                                , Tw.border_indigo_500
                                ]
                            , Bp.sm
                                [ Tw.text_sm
                                ]
                            ]
                        , Attr.placeholder "Bill Shakespeare"
                        ]
                        []
                    ]
                ]
            , div [ css [ mt_auto, mb_8, mx_4 ] ]
                [ button
                    ([ Attr.type_ "submit"
                     , css
                        [ relative
                        , w_full
                        , flex
                        , justify_center
                        , border
                        , border_transparent
                        , text_sm
                        , font_medium
                        , rounded_md
                        , text_white
                        , bg_indigo_600
                        , Css.focus
                            [ outline_none
                            , ring_2
                            , ring_offset_2
                            , ring_indigo_500
                            ]
                        , Css.hover [ bg_indigo_700 ]
                        ]
                     ]
                        ++ (if name == "" then
                                []

                            else
                                [ onClick AcceptInvitation ]
                           )
                    )
                    [ if joining then
                        text "Joining..."

                      else if name == "" then
                        text "Enter name to join production"

                      else
                        text ("Join production as " ++ name)
                    ]
                ]
            ]
        ]


cueingPage : CueingAction -> Html Msg
cueingPage cueingAction =
    div [ css [ py_10, h_full ] ]
        [ header []
            [ div
                [ css
                    [ max_w_7xl
                    , mx_auto
                    , px_4
                    , Bp.lg [ px_8 ]
                    , Bp.sm [ px_6 ]
                    ]
                ]
                [ h1
                    [ css
                        [ text_3xl
                        , font_bold
                        , leading_tight
                        , text_gray_900
                        ]
                    ]
                    [ case cueingAction of
                        Listening { speaker } ->
                            text ("(" ++ speaker ++ " speaking)")

                        Speaking { character } ->
                            text character

                        ShowOver ->
                            text ""
                    ]
                ]
            ]
        , main_ [ css [ h_full ] ]
            [ case cueingAction of
                ShowOver ->
                    text "That's all folks!"

                Listening { nextParts } ->
                    div
                        [ css
                            [ max_w_7xl
                            , mx_auto
                            , Bp.lg [ px_8 ]
                            , Bp.sm [ px_6 ]
                            , flex
                            , flex_col
                            , h_full
                            ]
                        ]
                        [ div
                            [ css
                                [ mt_auto
                                , pb_4
                                , mx_4
                                ]
                            ]
                            [ text
                                ("(Your next parts: "
                                    ++ String.join ", " nextParts
                                    ++ ")"
                                )
                            ]
                        ]

                Speaking { line } ->
                    div
                        [ css
                            [ max_w_7xl
                            , mx_auto
                            , Bp.lg [ px_8 ]
                            , Bp.sm [ px_6 ]
                            , flex
                            , flex_col
                            , h_full
                            ]
                        ]
                        [ div [ css [ px_4, py_8, Bp.sm [ px_0 ] ] ]
                            [ div [ css [ whitespace_pre_wrap ] ]
                                [ text line ]
                            ]
                        , div
                            [ css [ mt_auto, mb_8 ]
                            ]
                            [ button
                                [ Attr.type_ "submit"
                                , css
                                    [ relative
                                    , w_full
                                    , flex
                                    , justify_center
                                    , px_4
                                    , border
                                    , border_transparent
                                    , text_sm
                                    , font_medium
                                    , rounded_md
                                    , text_white
                                    , bg_indigo_600
                                    , Css.focus
                                        [ outline_none
                                        , ring_2
                                        , ring_offset_2
                                        , ring_indigo_500
                                        ]
                                    , Css.hover [ bg_indigo_700 ]
                                    ]
                                , onClick CueNextActor
                                ]
                                [ text "Cue next actor" ]
                            ]
                        ]
            ]
        ]


castingModal : Casting.CastingChoices -> ManualChoice -> Html Msg
castingModal currentCasting newChoice =
    let
        title =
            case newChoice of
                PartFor actor ->
                    "Cast actor " ++ actor ++ " as which part?"

                ActorFor part ->
                    "Cast part " ++ part ++ " as which actor?"

        choiceList =
            case newChoice of
                PartFor actor ->
                    allParts currentCasting
                        |> List.map
                            (\part ->
                                li
                                    [ css
                                        [ Tw.py_4
                                        ]
                                    , onClick (CastActorAsPart actor part)
                                    ]
                                    [ text part ]
                            )

                ActorFor part ->
                    allActors currentCasting
                        |> List.map
                            (\actor ->
                                li
                                    [ css
                                        [ Tw.py_4
                                        ]
                                    , onClick (CastActorAsPart actor part)
                                    ]
                                    [ text actor ]
                            )
    in
    div
        [ css
            [ Tw.fixed
            , Tw.z_10
            , Tw.inset_0
            , Tw.overflow_y_auto
            ]
        , Attr.attribute "aria-labelledby" "modal-title"
        , Attr.attribute "role" "dialog"
        , Attr.attribute "aria-modal" "true"
        ]
        [ div
            [ css
                [ Tw.flex
                , Tw.items_end
                , Tw.justify_center
                , Tw.min_h_screen
                , Tw.pt_4
                , Tw.px_4
                , Tw.pb_20
                , Tw.text_center
                , Bp.sm
                    [ Tw.block
                    , Tw.p_0
                    ]
                ]
            ]
            [ {-
                 Background overlay, show/hide based on modal state.

                 Entering: "ease-out duration-300"
                   From: "opacity-0"
                   To: "opacity-100"
                 Leaving: "ease-in duration-200"
                   From: "opacity-100"
                   To: "opacity-0"
              -}
              div
                [ css
                    [ Tw.fixed
                    , Tw.inset_0
                    , Tw.bg_gray_500
                    , Tw.bg_opacity_75
                    , Tw.transition_opacity
                    ]
                , Attr.attribute "aria-hidden" "true"
                ]
                []
            , {- This element is to trick the browser into centering the modal contents. -}
              span
                [ css
                    [ Tw.hidden
                    , Bp.sm
                        [ Tw.inline_block
                        , Tw.align_middle
                        , Tw.h_screen
                        ]
                    ]
                , Attr.attribute "aria-hidden" "true"
                ]
                [ text "\u{200B}" ]
            , {-
                 Modal panel, show/hide based on modal state.

                 Entering: "ease-out duration-300"
                   From: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                   To: "opacity-100 translate-y-0 sm:scale-100"
                 Leaving: "ease-in duration-200"
                   From: "opacity-100 translate-y-0 sm:scale-100"
                   To: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              -}
              div
                [ css
                    [ Tw.inline_block
                    , Tw.align_bottom
                    , Tw.bg_white
                    , Tw.rounded_lg
                    , Tw.px_4
                    , Tw.pt_5
                    , Tw.pb_4
                    , Tw.text_left
                    , Tw.overflow_hidden
                    , Tw.shadow_xl
                    , Tw.transform
                    , Tw.transition_all
                    , Bp.sm
                        [ Tw.my_8
                        , Tw.align_middle
                        , Tw.max_w_lg
                        , Tw.w_full
                        , Tw.p_6
                        ]
                    ]
                ]
                [ div []
                    [ div
                        [ css
                            [ Tw.mx_auto
                            , Tw.flex
                            , Tw.items_center
                            , Tw.justify_center
                            , Tw.h_12
                            , Tw.w_12
                            , Tw.rounded_full
                            , Tw.bg_green_100
                            ]
                        ]
                        [{- Heroicon name: outline/check -}]
                    , div
                        [ css
                            [ Tw.mt_3
                            , Tw.text_center
                            , Bp.sm
                                [ Tw.mt_5
                                ]
                            ]
                        ]
                        [ h3
                            [ css
                                [ Tw.text_lg
                                , Tw.leading_6
                                , Tw.font_medium
                                , Tw.text_gray_900
                                ]
                            , Attr.id "modal-title"
                            ]
                            [ text title ]
                        , div
                            [ css
                                [ Tw.mt_2
                                ]
                            ]
                            [ p
                                [ css
                                    [ Tw.text_sm
                                    , Tw.text_gray_500
                                    ]
                                ]
                                [ ul
                                    [ Attr.attribute "role" "list"
                                    , css [ Tw.divide_y, Tw.divide_gray_200 ]
                                    ]
                                    choiceList
                                ]
                            ]
                        ]
                    ]
                , div
                    [ css
                        [ Tw.mt_5
                        , Bp.sm
                            [ Tw.mt_6
                            , Tw.grid
                            , Tw.grid_cols_2
                            , Tw.gap_3
                            , Tw.grid_flow_row_dense
                            ]
                        ]
                    ]
                    [ button
                        [ Attr.type_ "button"
                        , css
                            [ Tw.w_full
                            , Tw.inline_flex
                            , Tw.justify_center
                            , Tw.rounded_md
                            , Tw.border
                            , Tw.border_transparent
                            , Tw.shadow_sm
                            , Tw.px_4
                            , Tw.py_2
                            , Tw.bg_indigo_600
                            , Tw.text_base
                            , Tw.font_medium
                            , Tw.text_white
                            , Css.focus
                                [ Tw.outline_none
                                , Tw.ring_2
                                , Tw.ring_offset_2
                                , Tw.ring_indigo_500
                                ]
                            , Css.hover
                                [ Tw.bg_indigo_700
                                ]
                            , Bp.sm
                                [ Tw.col_start_2
                                , Tw.text_sm
                                ]
                            ]
                        ]
                        [ text "Choose" ]
                    , button
                        [ Attr.type_ "button"
                        , onClick CancelModal
                        , css
                            [ Tw.mt_3
                            , Tw.w_full
                            , Tw.inline_flex
                            , Tw.justify_center
                            , Tw.rounded_md
                            , Tw.border
                            , Tw.border_gray_300
                            , Tw.shadow_sm
                            , Tw.px_4
                            , Tw.py_2
                            , Tw.bg_white
                            , Tw.text_base
                            , Tw.font_medium
                            , Tw.text_gray_700
                            , Css.focus
                                [ Tw.outline_none
                                , Tw.ring_2
                                , Tw.ring_offset_2
                                , Tw.ring_indigo_500
                                ]
                            , Css.hover
                                [ Tw.bg_gray_50
                                ]
                            , Bp.sm
                                [ Tw.mt_0
                                , Tw.col_start_1
                                , Tw.text_sm
                                ]
                            ]
                        ]
                        [ text "Cancel" ]
                    ]
                ]
            ]
        ]



--  ____                    _   _      _
-- |  _ \ __ _  __ _  ___  | | | | ___| |_ __   ___ _ __ ___
-- | |_) / _` |/ _` |/ _ \ | |_| |/ _ \ | '_ \ / _ \ '__/ __|
-- |  __/ (_| | (_| |  __/ |  _  |  __/ | |_) |  __/ |  \__ \
-- |_|   \__,_|\__, |\___| |_| |_|\___|_| .__/ \___|_|  |___/
--             |___/                    |_|
-- Page Helpers


tMenu : String -> Html msg
tMenu title =
    div
        [ css [ flex ] ]
        [ div [ css [ flex_shrink_0, flex, items_center ] ]
            [ img
                [ css [ block, h_8, w_auto ]
                , Attr.src "https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg"
                , Attr.alt "Logo"
                ]
                []
            ]
        , div [ css [ neg_my_px, ml_6, flex, space_x_8 ] ]
            [ div
                [ css
                    [ text_gray_900
                    , inline_flex
                    , items_center
                    , px_1
                    , pt_1
                    , text_lg
                    , font_medium
                    ]
                ]
                [ text title ]
            ]
        ]


emptyTemplate =
    Html.text ""


intentionTestCaseSelector =
    div
        [ css
            [ Tw.absolute
            , Tw.z_50
            , Tw.neg_mr_2
            , Tw.flex
            , Tw.items_center
            ]
        ]
        [ {- Mobile menu button -}
          button
            [ Attr.type_ "button"
            , onClick AdvanceIntentionTestCase
            , css
                [ Tw.bg_white
                , Tw.inline_flex
                , Tw.items_center
                , Tw.justify_center
                , Tw.p_2
                , Tw.rounded_md
                , Tw.text_gray_400
                , Css.focus
                    [ Tw.outline_none
                    , Tw.ring_2
                    , Tw.ring_offset_2
                    , Tw.ring_indigo_500
                    ]
                , Css.hover
                    [ Tw.text_gray_500
                    , Tw.bg_gray_100
                    ]
                ]
            , Attr.attribute "aria-controls" "mobile-menu"
            , Attr.attribute "aria-expanded" "false"
            ]
            [ {-
                 Heroicon name: outline/menu

                 Menu open: "hidden", Menu closed: "block"
              -}
              svg
                [ SvgAttr.css
                    [ Tw.block
                    , Tw.h_6
                    , Tw.w_6
                    ]
                , SvgAttr.fill "none"
                , SvgAttr.viewBox "0 0 24 24"
                , SvgAttr.stroke "currentColor"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ path
                    [ SvgAttr.strokeLinecap "round"
                    , SvgAttr.strokeLinejoin "round"
                    , SvgAttr.strokeWidth "2"
                    , SvgAttr.d "M4 6h16M4 12h16M4 18h16"
                    ]
                    []
                ]
            , {-
                 Heroicon name: outline/x

                 Menu open: "block", Menu closed: "hidden"
              -}
              svg
                [ SvgAttr.css
                    [ Tw.hidden
                    , Tw.h_6
                    , Tw.w_6
                    ]
                , SvgAttr.fill "none"
                , SvgAttr.viewBox "0 0 24 24"
                , SvgAttr.stroke "currentColor"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ path
                    [ SvgAttr.strokeLinecap "round"
                    , SvgAttr.strokeLinejoin "round"
                    , SvgAttr.strokeWidth "2"
                    , SvgAttr.d "M6 18L18 6M6 6l12 12"
                    ]
                    []
                ]
            ]
        ]



--  ___       _             _   _
-- |_ _|_ __ | |_ ___ _ __ | |_(_) ___  _ __
--  | || '_ \| __/ _ \ '_ \| __| |/ _ \| '_ \
--  | || | | | ||  __/ | | | |_| | (_) | | | |
-- |___|_| |_|\__\___|_| |_|\__|_|\___/|_| |_|
--
--  _____         _      ____
-- |_   _|__  ___| |_   / ___|__ _ ___  ___  ___
--   | |/ _ \/ __| __| | |   / _` / __|/ _ \/ __|
--   | |  __/\__ \ |_  | |__| (_| \__ \  __/\__ \
--   |_|\___||___/\__|  \____\__,_|___/\___||___/
-- Intention Test Cases for states that need visual testing.
-- intentionTestCases is a non-empty list, so we can be sure
-- the cases parse, and easily load one into the view with
-- `intention = Tuple.first intentionTestCases`


intentionTestCases : List Intention
intentionTestCases =
    [ {- This example is a basic casting example with a simple script and actor set. -}
      Casting
        { casting =
            [ { actors = [ "Ron" ], parts = [ "Dwight" ] }
            , { actors = [ "Jorge" ], parts = [ "Phylis" ] }
            , { actors = [ "Jimmy Eat Wales" ], parts = [ "Angela" ] }
            ]
        , invitationLink = "I always just say I'm from queens"
        , script = Script "The Office" []
        , manualCasting = Just (PartFor "Dwight")
        }

    {- This example is a basic example of after someone clicks an invite link -}
    , Accepting { script = Script "Hamlet" [], director = "Ignatius", directorId = "1", joining = False }
    , Loading
    ]
        ++ (let
                s =
                    { title = "Hamlet"
                    , lines =
                        [ { speaker = "Hamlet"
                          , line = "As happy prologues to the swelling act\nOf the imperial theme.—I thank you, gentlemen.\n[Aside] This supernatural soliciting\nCannot be ill, cannot be good: if ill,\nWhy hath it given me earnest of success,\nCommencing in a truth? I am thane of Cawdor:\nIf good, why do I yield to that suggestion\nWhose horrid image doth unfix my hair\nAnd make my seated heart knock at my ribs,\nAgainst the use of nature? Present fears\nAre less than horrible imaginings:\nMy thought, whose murder yet is but fantastical,\nShakes so my single state of man that function\nIs smother'd in surmise, and nothing is\nBut what is not. "
                          , title = ""
                          , part = ""
                          }
                        , { speaker = "Banquo"
                          , line = "Oh the transformation is happening. Anna Oh, yep. Is turning into a horse. He's turning into a horse. Look at that now is a horse. Now I'm going to fight the horse. Had a run runs a safety forever away from here. Run Hannah. What? Stop that horse, you get off of that?"
                          , title = ""
                          , part = ""
                          }
                        ]
                    }
            in
            [ Cueing
                { script = s
                , casting = castByLineFrequency s.lines [ "" ] -- "" is default name, so Cueing
                , lineNumber = 0 -- Test poetic line with linebreaks
                }
            , Cueing
                { script = s
                , casting = castByLineFrequency s.lines [ "" ] -- "" is default name, so Cueing
                , lineNumber = 1 -- Test long line
                }
            , Cueing
                { script = s
                , casting = castByLineFrequency s.lines [ "Jeff" ] -- Listening
                , lineNumber = 0
                }
            ]
           )
