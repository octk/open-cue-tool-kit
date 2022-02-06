module Actor exposing (AcceptingDetails, CueingAction(..), CueingDetails, Model(..), Msg(..), PlatformCmd(..), PlatformResponse(..), acceptInvitationHelper, acceptingPage, cueingPage, incrementLineNumberHelper, interfaceTestCases, makeCueingAction, update, updateFromPlatform, view)

import Casting exposing (Script)
import Css
import Css.Global
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events exposing (onClick)
import Interface exposing (appHeight)
import List.Extra as List
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
    = Cueing CueingDetails
    | Accepting AcceptingDetails


type alias CueingDetails =
    { script : Script
    , casting : Casting.CastingChoices
    , lineNumber : Int
    , name : String
    }


type alias AcceptingDetails =
    { script : Script
    , director : String
    , directorId : String
    , joining : Bool
    , name : String
    }


type Msg
    = AcceptInvitation
    | ChangeName String
    | CueNextActor


type PlatformResponse
    = ConsiderInvite Script String
    | StartCueing Casting.CastingChoices
    | IncrementLineNumber
    | SetState
        { script : Script
        , name : String
        , casting : Casting.CastingChoices
        , lineNumber : Int
        }


type PlatformCmd
    = JoinProduction String String
    | AdvanceCue
    | NoCmd


view : Model -> Html Msg
view model =
    case model of
        Cueing cueDetails ->
            cueingPage (makeCueingAction cueDetails)

        Accepting acceptingDetails ->
            acceptingPage acceptingDetails


acceptingPage : AcceptingDetails -> Html Msg
acceptingPage { script, director, joining, name } =
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
                , Bp.lg [ px_8 ]
                , Bp.sm [ px_6 ]
                ]
            , appHeight
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
                            , my_2
                            ]
                        ]
                        [ text
                            ("Join a production of "
                                ++ String.replace ".json" "" (String.replace "_" " " script.title)
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
                        , flex_col
                        , justify_center
                        , items_center
                        , border
                        , border_transparent
                        , text_sm
                        , font_medium
                        , rounded_md
                        , text_white
                        , bg_indigo_600
                        , h_12
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
    div [ css [ py_6, h_full ] ]
        [ header []
            [ div
                [ css
                    [ max_w_7xl
                    , mx_auto
                    , px_4
                    , pb_4
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
        , main_
            [ Attr.style "height" "calc(100% - 200px)"
            ]
            [ case cueingAction of
                ShowOver ->
                    text ""

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
                        [ div
                            [ css
                                [ min_h_0
                                , overflow_y_scroll
                                , px_4
                                , Bp.sm [ px_0 ]
                                , whitespace_pre_wrap
                                ]
                            , Attr.style "touch-action" "pan-up"
                            ]
                            [ text line ]
                        , div
                            [ css [ mt_auto, mb_12, mt_6 ]
                            ]
                            [ button
                                [ Attr.type_ "submit"
                                , css
                                    [ relative
                                    , w_full
                                    , flex
                                    , flex_col
                                    , items_center
                                    , justify_center
                                    , px_4
                                    , border
                                    , border_transparent
                                    , text_sm
                                    , font_medium
                                    , rounded_md
                                    , text_white
                                    , bg_indigo_600
                                    , h_10
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


type CueingAction
    = Listening { speaker : String, nextParts : List String }
    | Speaking { line : String, character : String }
    | ShowOver


makeCueingAction : CueingDetails -> CueingAction
makeCueingAction { script, casting, lineNumber, name } =
    let
        myParts =
            Casting.whichPartsAreActor name casting

        currentLine =
            List.getAt lineNumber script.lines

        nextParts =
            List.map .speaker script.lines
                |> List.filter (\speaker -> List.member speaker myParts)
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


update : Msg -> Model -> ( Model, PlatformCmd )
update msg model =
    case msg of
        AcceptInvitation ->
            acceptInvitationHelper model

        ChangeName newName ->
            case model of
                Accepting state ->
                    ( Accepting { state | name = newName }, NoCmd )

                _ ->
                    ( model, NoCmd )

        CueNextActor ->
            ( model, AdvanceCue )


updateFromPlatform : PlatformResponse -> Model -> ( Model, PlatformCmd )
updateFromPlatform response model =
    case response of
        IncrementLineNumber ->
            incrementLineNumberHelper model

        ConsiderInvite script clientId ->
            ( Accepting
                { script = script
                , director = "Director "
                , directorId = clientId
                , joining = False
                , name = ""
                }
            , NoCmd
            )

        StartCueing casting ->
            case model of
                Accepting { script, name } ->
                    ( Cueing
                        { script = script
                        , casting = casting
                        , lineNumber = 0
                        , name = name
                        }
                    , NoCmd
                    )

                _ ->
                    ( model, NoCmd )

        SetState { script, name, casting, lineNumber } ->
            ( Cueing
                { script = script
                , casting = casting
                , lineNumber = lineNumber
                , name = name
                }
            , NoCmd
            )


incrementLineNumberHelper model =
    case model of
        Cueing details ->
            ( Cueing { details | lineNumber = details.lineNumber + 1 }, NoCmd )

        _ ->
            ( model, NoCmd )


acceptInvitationHelper : Model -> ( Model, PlatformCmd )
acceptInvitationHelper model =
    let
        addJoining details =
            { details | joining = True }
    in
    case model of
        Accepting ({ directorId, name } as details) ->
            ( Accepting (addJoining details), JoinProduction name directorId )

        _ ->
            ( model, NoCmd )


interfaceTestCases =
    [ {- This example is a basic example of after someone clicks an invite link -}
      Accepting
        { script = Script "Hamlet" []
        , director = "Ignatius"
        , directorId = "1"
        , joining = False
        , name = ""
        }
    , Cueing
        { script = testScript2
        , casting = Casting.castByLineFrequency testScript2.lines [ "" ] -- "" is default name, so Cueing
        , lineNumber = 0 -- Test poetic line with linebreaks
        , name = ""
        }
    , Cueing
        { script = testScript2
        , casting = Casting.castByLineFrequency testScript2.lines [ "" ] -- "" is default name, so Cueing
        , lineNumber = 1 -- Test long line
        , name = ""
        }
    , Cueing
        { script = testScript2
        , casting = Casting.castByLineFrequency testScript2.lines [ "Jeff" ] -- Listening
        , lineNumber = 0
        , name = ""
        }
    ]
