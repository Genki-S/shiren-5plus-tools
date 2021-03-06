module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Css exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Inventory
import Item exposing (BlessState(..), Item, Kind(..))



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = \m -> view m |> toUnstyled
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }



---- MODEL ----


type alias Model =
    { inventory : Result String (List Item)
    , priceInput : Int
    , showCredit : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { inventory = Inventory.generate
      , priceInput = 0
      , showCredit = True
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = PressNumber Int
    | ClearInput
    | HideCredit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PressNumber i ->
            let
                newPriceInput =
                    model.priceInput * 10 + i
            in
            ( { model | priceInput = newPriceInput }, Cmd.none )

        ClearInput ->
            ( { model | priceInput = 0 }, Cmd.none )

        HideCredit ->
            ( { model | showCredit = False }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "container", css [ Css.height (pct 100) ] ]
        [ if model.showCredit then
            viewCredit

          else
            span [] []
        , div [ css [ Css.height (pct 60), overflowY scroll ] ] [ viewItems model ]
        , div
            [ css
                [ position fixed
                , Css.height (pct 40)
                , bottom (px 0)
                , right (px 0)
                , left (px 0)
                , backgroundColor (hex "EEEEEE")
                ]
            ]
            [ viewPriceInput model ]
        ]


viewCredit : Html Msg
viewCredit =
    div [ class "alert alert-dismissible alert-info" ]
        [ text "本アプリは2020/02/08時点での"
        , a [ href "https://seesaawiki.jp/w/shiren5/d/%C3%CD%C3%CA%B0%EC%CD%F7%C9%BD" ]
            [ text "風来のシレン５ フォーチュンタワーと運命のダイス Wiki" ]
        , text "様の情報を元に作成されました"
        , button [ class "close", onClick HideCredit ] [ text "×" ]
        ]


viewItems : Model -> Html Msg
viewItems model =
    case model.inventory of
        Err msg ->
            div [ class "alert alert-danger" ] [ text msg ]

        Ok items ->
            let
                allItems =
                    items
                        |> List.map (\i -> [ i, Item.asBlessed i, Item.asCursed i ])
                        |> List.concat

                priceMatches item =
                    let
                        i =
                            Item.exposeInternals item

                        buyingPrice =
                            Item.calculateBuyingPrice item

                        sellingPrice =
                            Item.calculateSellingPrice item
                    in
                    model.priceInput == buyingPrice || model.priceInput == sellingPrice

                filteredItems =
                    case model.priceInput of
                        0 ->
                            allItems

                        _ ->
                            List.filter priceMatches allItems
            in
            Html.Styled.table [ class "table" ]
                [ thead [ class "thead-dark" ]
                    [ th [] [ text "種別" ]
                    , th [] [ text "名前" ]
                    , th [] [ text "回数" ]
                    , th [] [ text "祝福" ]
                    , th [] [ text "買値" ]
                    , th [] [ text "売値" ]
                    ]
                , tbody []
                    (List.map viewItemRow filteredItems)
                ]


viewItemRow : Item -> Html Msg
viewItemRow item =
    let
        i =
            Item.exposeInternals item

        remainingText =
            case i.remaining of
                Nothing ->
                    ""

                Just r ->
                    String.fromInt r

        blessedText =
            case i.blessState of
                Nothing ->
                    ""

                Just Blessed ->
                    "祝福"

                Just Cursed ->
                    "呪い"
    in
    tr []
        [ td [] [ text (i.kind |> Item.kindToString) ]
        , td [] [ text i.name ]
        , td [] [ text remainingText ]
        , td [] [ text blessedText ]
        , td [] [ text (String.fromInt (Item.calculateBuyingPrice item)) ]
        , td [] [ text (String.fromInt (Item.calculateSellingPrice item)) ]
        ]


viewPriceInput : Model -> Html Msg
viewPriceInput model =
    div [ class "container", css [ padding (px 10) ] ]
        [ input
            [ class "form-control"
            , type_ "number"
            , value (String.fromInt model.priceInput)
            , Html.Styled.Attributes.disabled True
            , css [ textAlign right ]
            ]
            []
        , viewCalculator model
        ]


viewCalculator : Model -> Html Msg
viewCalculator model =
    let
        numberRows =
            [ [ 7, 8, 9 ], [ 4, 5, 6 ], [ 1, 2, 3 ] ]
                |> List.map (viewCalculatorRow model)

        lastRow =
            [ tr []
                [ viewCalculatorCell model 0 2
                , td [] [ viewCalculatorButton model ClearInput "C" ]
                ]
            ]

        rows =
            List.append numberRows lastRow
    in
    Html.Styled.table
        [ class "table table-borderless"
        , css [ textAlign center ]
        ]
        rows


viewCalculatorRow : Model -> List Int -> Html Msg
viewCalculatorRow model numbers =
    tr [] (List.map (\n -> viewCalculatorCell model n 1) numbers)


viewCalculatorCell : Model -> Int -> Int -> Html Msg
viewCalculatorCell model n cs =
    td [ colspan cs ]
        [ viewCalculatorButton model (PressNumber n) (String.fromInt n) ]


viewCalculatorButton : Model -> Msg -> String -> Html Msg
viewCalculatorButton model msgOnClick s =
    button
        [ class "btn btn-light"
        , onClick msgOnClick
        , css [ Css.width (pct 100) ]
        ]
        [ text s ]
