module Page.Index exposing (Data, Model, Msg, page)

import Browser
import Browser.Navigation
import Css
import Css.Global
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (..)
import Html.Styled.Events as Events exposing (onClick)
import MarkdownCodec
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import Sketch exposing (landingPage)
import Svg.Styled as Svg exposing (path, svg)
import Svg.Styled.Attributes as SvgAttr
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import TailwindMarkdownRenderer
import View exposing (View)


type alias Model =
    { collapsed : Bool }


type Msg
    = ToggleTodo


type alias RouteParams =
    {}


page : Page.PageWithState RouteParams Data Model Msg
page =
    Page.single
        { head = head
        , data = indexData
        }
        |> Page.buildWithLocalState
            { init = init
            , subscriptions = subscriptions
            , update = update
            , view = view
            }


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Cmd Msg )
init =
    \_ _ _ -> ( { collapsed = True }, Cmd.none )


subscriptions : Maybe PageUrl -> RouteParams -> path -> Model -> Sub Msg
subscriptions =
    \_ _ _ _ -> Sub.none


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update url key sharedModel static msg model =
    case msg of
        ToggleTodo ->
            ( { model | collapsed = not model.collapsed }, Cmd.none )


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    List (Html Msg)


indexData : DataSource Data
indexData =
    MarkdownCodec.withoutFrontmatter
        TailwindMarkdownRenderer.renderer
        "content/index.md"


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "CueCannon"
    , body =
        --[ landingPage ]
        List.map toUnstyled
            [ template static
            ]
    }


template static =
    div []
        [ node "link"
            [ Attr.rel "stylesheet"
            , Attr.href "https://unpkg.com/tailwindcss@2.2.19/dist/tailwind.min.css"
            ]
            []
        , stylesheet
        , div
            [ class "quicksand"
            , css
                [ Tw.bg_gray_100
                , Tw.text_gray_700
                , Tw.font_sans
                ]
            ]
            [ div
                [ css
                    [ Tw.p_6
                    , Tw.flex
                    , Tw.flex_wrap
                    , Bp.md
                        [ Tw.p_16
                        ]
                    , Bp.sm
                        [ Tw.p_10
                        ]
                    ]
                ]
                [ div
                    [ css
                        [ Tw.w_full
                        , Tw.order_3
                        , Bp.md
                            [ Tw.w_1over2
                            , Tw.pr_32
                            , Tw.order_1
                            ]
                        ]
                    ]
                    [ div
                        [ css
                            [ Tw.max_w_md
                            , Tw.leading_loose
                            , Tw.tracking_tight
                            , Bp.md
                                [ Tw.float_right
                                , Tw.text_right
                                , Tw.sticky
                                , Tw.top_0
                                ]
                            ]
                        ]
                        [ p
                            [ css
                                [ Tw.font_bold
                                , Tw.my_4
                                , Bp.md
                                    [ Tw.my_12
                                    ]
                                ]
                            ]
                            [ img [ alt "logo", src "/bow.svg" ] [] ]
                        , ul
                            [ css
                                [ Tw.flex
                                , Tw.flex_wrap
                                , Tw.justify_between
                                , Tw.flex_col
                                ]
                            ]
                            [ li []
                                [ a
                                    [ Attr.href "#"
                                    , class "nav"
                                    ]
                                    [ text "Previous blog posts links" ]
                                ]
                            ]
                        , a
                            [ Attr.href "#"
                            , css
                                [ Tw.font_bold
                                , Css.hover
                                    [ Tw.font_bold
                                    ]
                                ]
                            ]
                            [ text "more..." ]
                        ]
                    ]
                , div
                    [ css
                        [ Tw.w_full
                        , Tw.order_1
                        , Bp.md
                            [ Tw.w_1over2
                            , Tw.order_2
                            ]
                        ]
                    ]
                    static.data
                , div
                    [ css
                        [ Tw.w_full
                        , Tw.pt_12
                        , Tw.order_4
                        , Bp.md
                            [ Tw.w_1over2
                            , Tw.pr_32
                            , Tw.pt_0
                            , Tw.sticky
                            , Tw.bottom_0
                            , Tw.order_3
                            ]
                        ]
                    ]
                    [ div
                        [ css
                            [ Tw.max_w_md
                            , Tw.leading_loose
                            , Tw.tracking_tight
                            , Bp.md
                                [ Tw.float_right
                                , Tw.text_right
                                , Tw.mb_16
                                ]
                            ]
                        ]
                        [ p
                            [ css
                                [ Tw.font_bold
                                , Tw.my_4
                                , Bp.md
                                    [ Tw.my_12
                                    ]
                                ]
                            ]
                            [ text "Contact" ]
                        , ul
                            [ css
                                [ Tw.flex
                                , Tw.flex_wrap
                                , Tw.justify_between
                                , Tw.flex_row
                                , Bp.md
                                    [ Tw.flex_col
                                    ]
                                ]
                            ]
                            [ li []
                                [ a
                                    [ Attr.href "#"
                                    , class "nav"
                                    , css
                                        [ Tw.mx_2
                                        , Bp.md
                                            [ Tw.mx_0
                                            ]
                                        ]
                                    ]
                                    [ text "Email" ]
                                ]
                            , li []
                                [ a
                                    [ Attr.href "#"
                                    , class "nav"
                                    , css
                                        [ Tw.mx_2
                                        , Bp.md
                                            [ Tw.mx_0
                                            ]
                                        ]
                                    ]
                                    [ text "Calendar" ]
                                ]
                            , li []
                                [ a
                                    [ Attr.href "#"
                                    , class "nav"
                                    , css
                                        [ Tw.mx_2
                                        , Bp.md
                                            [ Tw.mx_0
                                            ]
                                        ]
                                    ]
                                    [ text "Discord" ]
                                ]
                            ]
                        ]
                    ]
                , div
                    [ css
                        [ Tw.w_full
                        , Tw.order_2
                        , Bp.md
                            [ Tw.w_1over2
                            , Tw.order_4
                            ]
                        ]
                    ]
                    [ div
                        [ css
                            [ Tw.hidden
                            , Tw.max_w_md
                            , Tw.leading_loose
                            , Tw.tracking_tight
                            ]
                        ]
                        [ p
                            [ css
                                [ Tw.font_bold
                                , Tw.my_4
                                , Bp.md
                                    [ Tw.my_12
                                    ]
                                ]
                            ]
                            [ text "About Me" ]
                        , p
                            [ css
                                [ Tw.mb_8
                                ]
                            ]
                            [ text "Arcu risus quis varius quam quisque id diam vel. Consectetur adipiscing elit ut aliquam purus sit amet. Nibh tortor id aliquet lectus proin nibh." ]
                        ]
                    ]
                ]
            , {- Pin to top right corner -}
              div
                [ css
                    [ Tw.absolute
                    , Tw.top_0
                    , Tw.right_0
                    , Tw.h_12
                    , Tw.w_12
                    , Tw.p_4
                    ]
                ]
                [ button
                    [ css
                        [ --Tw.js_change_theme,
                          Css.focus
                            [ Tw.outline_none
                            ]
                        ]
                    ]
                    [ text "🌙" ]
                ]

            {- ,              jQuery if you need it
               <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>


                       node "script" []
                           [ text "//Toggle mode const toggle = document.querySelector('.js-change-theme'); const body = document.querySelector('body'); //const profile = document.getElementById('profile'); toggle.addEventListener('click', () => { if (body.classList.contains('text-gray-700')) { toggle.innerHTML = "☀️"; body.classList.remove('text-gray-700'); body.classList.add('text-gray-300'); body.classList.remove('bg-gray-100'); body.classList.add('bg-gray-900'); } else { toggle.innerHTML = "🌙"; body.classList.remove('text-gray-300'); body.classList.add('text-gray-700'); body.classList.remove('bg-gray-900'); body.classList.add('bg-gray-100'); } });" ]
            -}
            ]
        ]


stylesheet =
    {- Replace with your tailwind.css once created -}
    node "style"
        []
        [ text ".quicksand { font-family: 'Nunito', sans-serif; } ::selection { background: #E9D8FD; color:#202684; /* WebKit/Blink Browsers */ } ::-moz-selection { background: #E9D8FD; color:#202684; /* Gecko Browsers */ } a:not(.nav) { font-weight: bold; text-decoration: none; padding: 2px; background: linear-gradient(to right, #5A67D8, #5A67D8); background-repeat: repeat-x; background-size: 100% 2px; background-position: 0 95%; -webkit-transition: all 150ms ease-in-out; -moz-transition: all 150ms ease-in-out; -ms-transition: all 150ms ease-in-out; -o-transition: all 150ms ease-in-out; transition: all 150ms ease-in-out; } a:hover { color: #B794F4; font-weight: bold; text-decoration: none; padding-bottom: 2px; background: linear-gradient(to right, #9F7AEA, #E9D8FD); background-repeat: repeat-x; background-size: 100% 2px; background-position: 50% 95%; -webkit-transition: color 150ms ease-in-out; -moz-transition: color 150ms ease-in-out; -ms-transition: color 150ms ease-in-out; -o-transition: color 150ms ease-in-out; transition: color 150ms ease-in-out; } a:focus { outline: none; background: #E9D8FD; }" ]


link : String -> String -> Html msg
link copy url =
    a [ Attr.href url, Attr.target "_blank" ] [ text copy ]
