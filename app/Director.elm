module Director exposing (Actor, CastingDetails, ManualChoice(..), Model(..), Msg(..), Part, PlatformCmd(..), PlatformResponse(..), actorJoinedHelper, alreadyCastPartsAndActors, beginShowHelper, browsingPage, cancelModalHelper, castHelper, castingModal, castingPage, castingSwitch, considerCastingChoiceHelper, initialize, interfaceTestCases, mapCasting, pickScriptHelper, toggleAutocastHelper, update, updateFromPlatform, view, yetUncastActors, yetUncastParts)

import Casting exposing (..)
import Css
import Css.Global
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events exposing (onClick)
import Interface exposing (appHeight, emptyTemplate, loadingPage)
import Loading
    exposing
        ( LoaderType(..)
        , defaultConfig
        , render
        )
import QRCode
import Svg.Attributes as SvgA
import Svg.Styled as Svg exposing (path, svg)
import Svg.Styled.Attributes as SvgAttr
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw exposing (..)
import TestScript exposing (testScript, testScript2)


type Model
    = Browsing (List Script) String
    | Casting CastingDetails
    | WaitingForScripts


type Msg
    = PickScript Script
    | ToggleAutocast
    | CancelModal
    | ConsiderCastingChoice ManualChoice
    | CastActorAsPart Actor Part
    | BeginShow


type PlatformResponse
    = AddScripts (List Script) String
    | ActorJoined String String


type PlatformCmd
    = MakeInvitation Script
    | ShareProduction CastingChoices
    | NoCmd


type alias CastingDetails =
    { casting : CastingChoices
    , script : Script
    , manualCasting : Maybe ManualChoice
    , autocast : Bool
    , host : Maybe String
    }


view : Model -> Html Msg
view model =
    case model of
        Casting cast ->
            castingPage cast

        Browsing scripts _ ->
            browsingPage scripts

        WaitingForScripts ->
            loadingPage


browsingPage scripts =
    div [ css [ overflow_y_scroll ], appHeight ]
        [ ul
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
        ]


castingPage { casting, manualCasting, autocast, host } =
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
            , Bp.sm
                [ rounded_md
                ]
            ]
        , appHeight
        ]
        [ div [ css [ flex, flex_col, h_full ] ]
            [ div []
                [ div
                    [ css
                        [ flex
                        , items_center
                        , justify_center
                        , bg_gray_50
                        , py_4
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
                                            (QRCode.toSvg [ SvgA.width "200px", SvgA.height "200px" ]
                                                >> fromUnstyled
                                            )
                                        |> Result.withDefault (text "Error while encoding to QRCode.")
                                    ]

                                Nothing ->
                                    []
                            )

                        -- , div []
                        --     [ button
                        --         [ Attr.type_ "submit"
                        --         , css
                        --             [ relative
                        --             , w_full
                        --             , flex
                        --             , justify_center
                        --             , py_2
                        --             , px_4
                        --             , border
                        --             , border_transparent
                        --             , text_sm
                        --             , font_medium
                        --             , rounded_md
                        --             , text_white
                        --             , bg_indigo_600
                        --             , Css.focus
                        --                 [ outline_none
                        --                 , ring_2
                        --                 , ring_offset_2
                        --                 , ring_indigo_500
                        --                 ]
                        --             , Css.hover [ bg_indigo_700 ]
                        --             ]
                        --         ]
                        --         [ text "Copy invitation link" ]
                        --     ]
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
            , div
                [ css
                    [ bg_gray_50
                    , mt_auto
                    , mb_24
                    , Bp.md [ mb_0 ]
                    ]
                ]
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


castingModal : CastingChoices -> ManualChoice -> Html Msg
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
        , Attr.style "touch-action" "none"
        ]
        [ div
            [ css
                [ Tw.flex
                , Tw.items_end
                , Tw.justify_center
                , Tw.pt_4
                , Tw.px_4
                , Tw.pb_20
                , Tw.text_center
                , Bp.sm
                    [ Tw.block
                    , Tw.p_0
                    ]
                ]
            , appHeight
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


type ManualChoice
    = PartFor Actor
    | ActorFor Part


type alias Actor =
    String


type alias Part =
    String


mapCasting : (CastingDetails -> CastingDetails) -> Model -> Model
mapCasting f model =
    case model of
        Casting details ->
            Casting (f details)

        other ->
            other


initialize : PlatformResponse -> ( Model, PlatformCmd )
initialize response =
    updateFromPlatform response WaitingForScripts


update : Msg -> Model -> ( Model, PlatformCmd )
update msg model =
    case msg of
        PickScript { title, lines } ->
            pickScriptHelper model title lines

        ToggleAutocast ->
            ( toggleAutocastHelper model, NoCmd )

        ConsiderCastingChoice choice ->
            ( mapCasting (considerCastingChoiceHelper choice) model, NoCmd )

        CastActorAsPart actor part ->
            castHelper actor part model

        BeginShow ->
            beginShowHelper model

        CancelModal ->
            ( mapCasting cancelModalHelper model, NoCmd )


updateFromPlatform : PlatformResponse -> Model -> ( Model, PlatformCmd )
updateFromPlatform response model =
    case response of
        ActorJoined name actorClientId ->
            ( mapCasting (actorJoinedHelper name actorClientId) model, NoCmd )

        AddScripts scripts host ->
            ( Browsing scripts host
            , NoCmd
            )


beginShowHelper : Model -> ( Model, PlatformCmd )
beginShowHelper model =
    case model of
        Casting { casting } ->
            ( model, ShareProduction casting )

        _ ->
            ( model, NoCmd )


pickScriptHelper :
    Model
    -> String
    -> List { line : String, part : String, speaker : String, title : String }
    -> ( Model, PlatformCmd )
pickScriptHelper model title lines =
    let
        hostUrl =
            case model of
                Browsing _ host ->
                    Just host

                _ ->
                    Nothing

        script =
            Script title lines
    in
    ( Casting
        { casting = makeEmptyCast lines []
        , manualCasting = Nothing
        , script = script
        , host = hostUrl
        , autocast = False
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
    ( mapCasting cast model, NoCmd )


toggleAutocastHelper model =
    let
        recast ({ casting, script, autocast } as details) =
            { details
                | casting =
                    if autocast then
                        castByLineFrequency script.lines (allActors casting)

                    else
                        casting
            }
    in
    mapCasting recast model


actorJoinedHelper : String -> String -> CastingDetails -> CastingDetails
actorJoinedHelper name actorClientId details =
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
            if details.autocast then
                castByLineFrequency details.script.lines (newActor :: currentActors)

            else
                addActor newActor details.casting
    }


interfaceTestCases =
    [ {- This example is a basic casting example with a simple script and actor set. -}
      Casting
        { casting =
            [ { actors = [ "Ron" ], parts = [ "Dwight" ] }
            , { actors = [ "Jorge" ], parts = [ "Phylis" ] }
            , { actors = [ "Jimmy Eat Wales" ], parts = [ "Angela" ] }
            ]
        , script = Script "The Office" []
        , manualCasting = Just (PartFor "Dwight")
        , host = Nothing
        , autocast = False
        }
    , Casting
        -- This tests the casting spacing for many characters
        { casting = makeEmptyCast testScript [ "Cory", "Brooke", "Michael" ]
        , script = { title = "", lines = testScript }
        , manualCasting = Nothing
        , host = Nothing
        , autocast = False
        }
    , Browsing
        --This tests selecting from a long list of scripts
        [ testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        , testScript2
        ]
        ""
    ]
