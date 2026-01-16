module ColorPicker exposing (script)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Html.String as Html
import Html.String.Attributes as Attr
import Kit
import Kit.Field as Field
import Kit.Script as Script


type alias Person =
    { name : String
    , bio : String
    , age : Int
    }


script : Script.Script
script =
    Script.define
        { name = "Color Picker"
        , task = task
        }
        |> Script.withDescription "Pick a color using elm-pages"


task : BackendTask FatalError ()
task =
    Field.fields Person
        |> Field.with (Field.text "Name" |> Field.placeholder "Enter your name" |> Field.required)
        |> Field.with (Field.textarea "Bio" { rows = 3 } |> Field.placeholder "Tell us about yourself")
        |> Field.with (Field.int "Age" |> Field.min 0 |> Field.max 120)
        |> Field.runFields
        |> BackendTask.andThen
            (\person ->
                Kit.arg
                    { placeholder = "Pick your favorite color"
                    , choices =
                        [ { name = "Red", value = "red", description = "", img = Nothing }
                        , { name = "Green", value = "green", description = "", img = Nothing }
                        , { name = "Blue", value = "blue", description = "", img = Nothing }
                        , { name = "Purple", value = "purple", description = "", img = Nothing }
                        , { name = "Orange", value = "orange", description = "", img = Nothing }
                        ]
                    }
                    |> BackendTask.andThen (\color -> showResult person color)
            )


showResult : Person -> String -> BackendTask FatalError ()
showResult person color =
    Kit.div
        (Html.div [ Attr.class "p-8 space-y-4" ]
            [ Html.h1
                [ Attr.class ("text-4xl font-bold text-" ++ color ++ "-500") ]
                [ Html.text ("Hello, " ++ person.name ++ "!") ]
            , Html.div [ Attr.class "text-lg text-gray-600" ]
                [ Html.text ("Age: " ++ String.fromInt person.age) ]
            , Html.div [ Attr.class "mt-4 p-4 bg-gray-100 rounded-lg" ]
                [ Html.h2 [ Attr.class "text-sm font-semibold text-gray-500 mb-2" ] [ Html.text "Bio" ]
                , Html.p [ Attr.class "text-gray-700" ] [ Html.text person.bio ]
                ]
            , Html.div
                [ Attr.class ("mt-4 inline-block px-4 py-2 rounded-full bg-" ++ color ++ "-100 text-" ++ color ++ "-700") ]
                [ Html.text ("Favorite color: " ++ color) ]
            ]
        )
