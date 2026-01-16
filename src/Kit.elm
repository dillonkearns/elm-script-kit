module Kit exposing
    ( arg
    , div
    , Choice
    , ArgOptions
    , Html
    )

{-| Elm bindings for ScriptKit.

@docs arg, div, Choice, ArgOptions, Html

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Html.String
import Json.Decode as Decode
import Json.Encode as Encode


{-| HTML type for building ScriptKit UI. Use with `Html.String` module.

    import Html.String as Html
    import Html.String.Attributes as Attr

    Kit.div
        (Html.div []
            [ Html.h1 [] [ Html.text "Hello!" ]
            ]
        )

-}
type alias Html =
    Html.String.Html Never


{-| A choice for the arg prompt.
-}
type alias Choice =
    { name : String
    , value : String
    }


{-| Options for the arg prompt.
-}
type alias ArgOptions =
    { placeholder : String
    , choices : List Choice
    }


{-| Prompt the user to select from a list of choices.

    Kit.arg
        { placeholder = "Choose a color"
        , choices =
            [ { name = "[R]ed", value = "red" }
            , { name = "[G]reen", value = "green" }
            , { name = "[B]lue", value = "blue" }
            ]
        }

-}
arg : ArgOptions -> BackendTask FatalError String
arg options =
    BackendTask.Custom.run "scriptKitArg"
        (encodeArgOptions options)
        Decode.string
        |> BackendTask.allowFatal


{-| Display HTML content in a ScriptKit window.

    import Html.String as Html

    Kit.div
        (Html.h1 [] [ Html.text "Hello, World!" ])

-}
div : Html -> BackendTask FatalError ()
div html =
    BackendTask.Custom.run "scriptKitDiv"
        (html |> Html.String.toString 0 |> Encode.string)
        (Decode.null ())
        |> BackendTask.allowFatal



-- Encoders


encodeArgOptions : ArgOptions -> Encode.Value
encodeArgOptions options =
    Encode.object
        [ ( "placeholder", Encode.string options.placeholder )
        , ( "choices", Encode.list encodeChoice options.choices )
        ]


encodeChoice : Choice -> Encode.Value
encodeChoice choice =
    Encode.object
        [ ( "name", Encode.string choice.name )
        , ( "value", Encode.string choice.value )
        ]
