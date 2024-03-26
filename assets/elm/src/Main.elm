module Main exposing (main)

import Browser
import Html exposing (Html)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Model
    = NoModel


type Msg
    = NoOp


init : () -> ( Model, Cmd Msg )
init _ =
    ( NoModel, Cmd.none )


view : Model -> Html Msg
view _ =
    Html.text "Hello world"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
