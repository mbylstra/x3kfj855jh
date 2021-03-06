module Apis.ColourLovers where

import ElmTest exposing (..)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (style)
import Http
import Json.Decode as Decode exposing (Decoder, (:=))
import Result exposing (Result(Ok))
import Task
-- import StartApp exposing (App)
import String
import Array exposing (Array)
import Color exposing(Color, rgb)

import Lib.ColorExtra exposing(toCssRgb)
import Lib.StringExtra exposing (hexToInt)


--------------------------------------------------------------------------------
-- MODEL
--------------------------------------------------------------------------------

type alias Palette =
  { title : String
  , userName : String
  , colors: Array Color
  }

type alias Model =
  { palettes : Maybe (Array Palette)
  , fetching : Bool
  }

initModel : Model
initModel =
  { palettes = Just Array.empty, fetching = True}


initEffects : Effects Action
initEffects =
  getTopPalettes

init : (Model, Effects Action)
init  =
  (initModel, initEffects)

getPalettes : Model -> Maybe (Array Palette)
getPalettes model =
  model.palettes

--------------------------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------------------------

type Action
    = PalettesFetched (Maybe (Array Palette))


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    PalettesFetched palettes ->
      ( { palettes = palettes
        , fetching = False
        }
      , Effects.none
      )

--------------------------------------------------------------------------------
-- VIEW
--------------------------------------------------------------------------------

(=>) : a  -> b -> ( a, b )
(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  div []
    [ palettesView model.palettes ]

-- colorToCss : Color -> String
-- colorToCss color =
--   let
--     color' = Color.toRgb color
--     colors =
--       [ color'.red
--       , color'.green
--       , color'.blue
--       ]
--     inner =
--       colors
--       |> List.map toString
--       |> String.join ","
--
--   in
--     "rgb(" ++ inner ++ ")"

colorView : Color -> Html
colorView color =
  div
    [ style
      [ "background-color" => toCssRgb color
      , "width" => "100px"
      , "height" => "100px"
      ]
    ]
    []

palettesView : Maybe (Array Palette) -> Html
palettesView maybePalettes =
  case maybePalettes of
    Just palettes ->
      div [] (Array.toList (Array.map paletteView palettes))
    Nothing ->
      p [] [text "error fetching palettes"]

paletteView : Palette -> Html
paletteView palette =
  div []
    [ h2 [] [text palette.title]
    , h4 [] [text palette.userName]
    , div [] (Array.toList (Array.map colorView palette.colors))
    ]

--------------------------------------------------------------------------------
-- EFFECTS
--------------------------------------------------------------------------------

topPalettesUrl : String
topPalettesUrl = "http://www.colourlovers.com/api/palettes/top?format=json"

crossOriginMeUrl : String
crossOriginMeUrl = "https://crossorigin.me/"
coTopPalettesUrl : String
coTopPalettesUrl = crossOriginMeUrl ++ topPalettesUrl

decodePalette : Decoder Palette
decodePalette =
    Decode.object3
      (\title userName colors -> {title=title, userName=userName, colors=colors})
      ("title" := Decode.string)
      ("userName" := Decode.string)
      ("colors" := Decode.array decodeColor)


decodeColor : Decoder Color
decodeColor =
  Decode.customDecoder Decode.string (\s -> Ok (parseColor s))


decodePalettes : Decoder (Array Palette)
decodePalettes = Decode.array decodePalette

getTopPalettes : Effects Action
getTopPalettes =
  Http.get decodePalettes coTopPalettesUrl
    |> Task.toMaybe
    |> Task.map PalettesFetched
    |> Effects.task


parseColor : String -> Color
parseColor str =
  let
    hexToInt' = hexToInt >> Result.toMaybe >> Maybe.withDefault 0
  in
    rgb
      (hexToInt' <| String.slice 0 2 str)
      (hexToInt' <| String.slice 2 4 str)
      (hexToInt' <| String.slice 4 6 str)

--------------------------------------------------------------------------------
-- TESTS
--------------------------------------------------------------------------------

tests : Test
tests =
  suite ""
    [ test ""
      (assertEqual
        (Decode.decodeString decodePalettes """
            [
              {
                "title": "goldfish",
                "userName": "kineko",
                "colors": ["AAA", "BBB"]
              },
              {
                "title": "title2",
                "userName": "user2",
                "colors": [CCC", "DDD"]
              }
            ]
          """
        )
        (Ok
          Array.empty
          -- [ {title="goldfish", userName="kineko", colors=["AAA", "BBB"]}
          -- , {title="title2", userName="user2", colors=["CCC", "DDD"]}
          -- ]
        )
      )
    , test ""
      (assertEqual
        (rgb 255 0 0)
        (parseColor "#FF0000")
      )
    , test ""
      (assertEqual
        (rgb 0 255 0)
        (parseColor "#00FF00")
      )
    , test ""
      (assertEqual
        (rgb 0 0 0)
        (parseColor "YOLO") -- defaults to black if there's a parse error
      )
    ]

-- main : Graphics.Element.Element
-- main =
--     elementRunner tests

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

-- app : App Model
-- app =
--   StartApp.start
--     { init = init
--     , update = update
--     , view = view
--     , inputs = []
--     }
--
-- main : Signal Html.Html
-- main =
--   app.html
--
-- port tasks : Signal (Task.Task Never ())
-- port tasks =
--   app.tasks
