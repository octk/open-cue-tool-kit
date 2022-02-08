module Interface exposing
    ( appHeight
    , appScaffolding
    , debuggingPage
    , emptyTemplate
    , genericPage
    , header
    , loadingPage
    )

import Casting exposing (..)
import Css
import Css.Global
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events exposing (onClick)
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



--  ____             __  __       _     _ _
-- / ___|  ___ __ _ / _|/ _| ___ | | __| (_)_ __   __ _
-- \___ \ / __/ _` | |_| |_ / _ \| |/ _` | | '_ \ / _` |
--  ___) | (_| (_| |  _|  _| (_) | | (_| | | | | | (_| |
-- |____/ \___\__,_|_| |_|  \___/|_|\__,_|_|_| |_|\__, |
--                                                |___/
-- Scaffolding is the ui on every page


appScaffolding :
    { menuOpen : Bool, menu : Html msg, toggleMsg : msg }
    -> Html msg
    -> Html msg
appScaffolding ({ menuOpen, menu, toggleMsg } as config) currentPage =
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
                , justify_start

                -- App wide PWA styling
                , select_none
                , fixed
                , overflow_hidden
                , overscroll_y_none
                ]

            -- iOS specific
            -- https://blog.opendigerati.com/the-eccentric-ways-of-ios-safari-with-the-keyboard-b5aa3f34228d
            , Attr.style "-webkit-tab-highlight-color" "rgba(255, 0, 0, 0.4)"
            , Attr.style "touch-action" "none"
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
                    [ div
                        [ css [ flex, justify_between, h_16 ] ]
                        [ menu
                        , tHamburger toggleMsg
                        ]
                    ]
                , div []
                    (if menuOpen then
                        [ tMenu ]

                     else
                        []
                    )
                ]
            , div [ css [ h_full ] ]
                [ currentPage
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


genericPage label filler =
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
                        , Tw.py_6
                        ]
                    ]
                    [ text label ]
                , filler
                ]
            ]
        ]


loadingPage =
    Loading.render Spinner { defaultConfig | color = "#4F46E5" } Loading.On
        |> Html.fromUnstyled
        |> genericPage "Loading"


debuggingPage errors =
    pre [] [ text (String.join "\n" errors) ]
        |> genericPage "Errors encountered"



--  ____                    _   _      _
-- |  _ \ __ _  __ _  ___  | | | | ___| |_ __   ___ _ __ ___
-- | |_) / _` |/ _` |/ _ \ | |_| |/ _ \ | '_ \ / _ \ '__/ __|
-- |  __/ (_| | (_| |  __/ |  _  |  __/ | |_) |  __/ |  \__ \
-- |_|   \__,_|\__, |\___| |_| |_|\___|_| .__/ \___|_|  |___/
--             |___/                    |_|
-- Page Helpers


header : Maybe msg -> Html msg
header testingMsg =
    div
        [ css [ flex ] ]
        [ div [ css [ flex_shrink_0, flex, items_center ] ]
            [ img
                ([ css [ block, h_8, w_auto ]
                 , Attr.src "https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg"
                 , Attr.alt "Logo"
                 ]
                    ++ (case testingMsg of
                            Just msg ->
                                [ onClick msg ]

                            Nothing ->
                                []
                       )
                )
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
                [ text "CueCannon" ]
            ]
        ]


tMenu =
    let
        style =
            {- Current: "bg-indigo-50 border-indigo-500 text-indigo-700", Default: "border-transparent text-gray-600 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-800" -}
            [ Tw.border_transparent
            , Tw.text_red_600
            , Tw.block
            , Tw.pl_3
            , Tw.pr_4
            , Tw.py_2
            , Tw.border_l_4
            , Tw.text_base
            , Tw.font_medium
            ]
    in
    div
        [ css [ Tw.pt_2, Tw.pb_3, Tw.space_y_1 ] ]
        [ a [ Attr.href "#", css style ]
            [ text "SERVER SETTINGS (careful!)" ]
        , a [ Attr.href "#", css style ]
            [ text "Toggle Debug" ]
        , a [ Attr.href "#", css style ]
            [ text "Reset Productions " ]
        ]


emptyTemplate =
    Html.text ""


appHeight =
    -- ios viewport tricky
    -- https://lukechannings.com/blog/2021-06-09-does-safari-15-fix-the-vh-bug/
    Attr.style "height" "calc(100% - 100px)"


tHamburger : msg -> Html msg
tHamburger toggleMsg =
    div
        [ css
            [ Tw.neg_mr_2
            , Tw.flex
            , Tw.items_center
            ]
        ]
        [ {- Menu button -}
          button
            [ Attr.type_ "button"
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
            , onClick toggleMsg
            ]
            [ span
                [ css
                    [ Tw.sr_only
                    ]
                ]
                [ text "Open main menu" ]
            , svg
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
            ]
        ]
