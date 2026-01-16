module Kit exposing
    ( arg, input, editor, Choice, ArgOptions
    , Fields, fields, withField, withNumberField, runFields
    , div, Html
    , selectFile, selectFolder
    , notify, say, copy
    , script
      -- Fields Builder
      -- File Picking
      -- User Input
      -- Display
      -- Utilities
    )

{-| Elm bindings for ScriptKit.


# User Input

@docs arg, input, editor, Choice, ArgOptions


# Fields Builder

@docs Fields, fields, withField, withNumberField, runFields


# Display

@docs div, Html


# File Picking

@docs selectFile, selectFolder


# Utilities

@docs notify, say, copy

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Html.String
import Json.Decode as Decode
import Json.Encode as Encode
import Pages.Script as Script



-- TYPES


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


{-| Builder for a multi-field form. Uses an applicative pattern for type safety.
-}
type Fields a
    = Fields
        { specs : List FieldSpec
        , decoder : Decode.Decoder a
        }


type alias FieldSpec =
    { label : String
    , fieldType : String
    }



-- USER INPUT


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


{-| Prompt the user for free text input.

    Kit.input "Enter your name"

-}
input : String -> BackendTask FatalError String
input placeholder =
    BackendTask.Custom.run "scriptKitInput"
        (Encode.string placeholder)
        Decode.string
        |> BackendTask.allowFatal


{-| Open a Monaco editor for text editing.

    -- Simple usage
    Kit.editor { content = "", language = Nothing }

    -- With initial content and language
    Kit.editor { content = "# Hello", language = Just "markdown" }

Languages: "javascript", "typescript", "markdown", "json", "html", "css", etc.

-}
editor : { content : String, language : Maybe String } -> BackendTask FatalError String
editor options =
    BackendTask.Custom.run "scriptKitEditor"
        (Encode.object
            [ ( "content", Encode.string options.content )
            , ( "language"
              , options.language
                    |> Maybe.map Encode.string
                    |> Maybe.withDefault Encode.null
              )
            ]
        )
        Decode.string
        |> BackendTask.allowFatal



-- FIELDS BUILDER


{-| Start building a multi-field form with a constructor function.

    Kit.fields (\name email age -> { name = name, email = email, age = age })
        |> Kit.withField "Name"
        |> Kit.withField "Email"
        |> Kit.withNumberField "Age"
        |> Kit.runFields

-}
fields : a -> Fields a
fields constructor =
    Fields
        { specs = []
        , decoder = Decode.succeed constructor
        }


{-| Add a text field to the form. Applies a String to the constructor.
-}
withField : String -> Fields (String -> a) -> Fields a
withField label (Fields f) =
    Fields
        { specs = f.specs ++ [ { label = label, fieldType = "text" } ]
        , decoder =
            Decode.map2 (<|)
                f.decoder
                (Decode.index (List.length f.specs) Decode.string)
        }


{-| Add a number field to the form. Applies a Float to the constructor.
-}
withNumberField : String -> Fields (Float -> a) -> Fields a
withNumberField label (Fields f) =
    let
        floatDecoder =
            Decode.string
                |> Decode.andThen
                    (\s ->
                        case String.toFloat s of
                            Just n ->
                                Decode.succeed n

                            Nothing ->
                                Decode.fail ("Expected a number but got: " ++ s)
                    )
    in
    Fields
        { specs = f.specs ++ [ { label = label, fieldType = "number" } ]
        , decoder =
            Decode.map2 (<|)
                f.decoder
                (Decode.index (List.length f.specs) floatDecoder)
        }


{-| Run the fields form and get the results.
-}
runFields : Fields a -> BackendTask FatalError a
runFields (Fields f) =
    BackendTask.Custom.run "scriptKitFields"
        (Encode.list encodeFieldSpec f.specs)
        f.decoder
        |> BackendTask.allowFatal


encodeFieldSpec : FieldSpec -> Encode.Value
encodeFieldSpec spec =
    Encode.object
        [ ( "label", Encode.string spec.label )
        , ( "type", Encode.string spec.fieldType )
        ]



-- DISPLAY


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



-- FILE PICKING


{-| Open a native file picker dialog.

    Kit.selectFile
        |> BackendTask.andThen
            (\filePath ->
                -- do something with filePath
            )

-}
selectFile : BackendTask FatalError String
selectFile =
    BackendTask.Custom.run "scriptKitSelectFile"
        Encode.null
        Decode.string
        |> BackendTask.allowFatal


{-| Open a native folder picker dialog.

    Kit.selectFolder
        |> BackendTask.andThen
            (\folderPath ->
                -- do something with folderPath
            )

-}
selectFolder : BackendTask FatalError String
selectFolder =
    BackendTask.Custom.run "scriptKitSelectFolder"
        Encode.null
        Decode.string
        |> BackendTask.allowFatal



-- UTILITIES


{-| Show a system notification.

    Kit.notify "Build complete!"

-}
notify : String -> BackendTask FatalError ()
notify message =
    BackendTask.Custom.run "scriptKitNotify"
        (Encode.string message)
        (Decode.null ())
        |> BackendTask.allowFatal


{-| Speak text using text-to-speech.

    Kit.say "Hello, world!"

-}
say : String -> BackendTask FatalError ()
say text =
    BackendTask.Custom.run "scriptKitSay"
        (Encode.string text)
        (Decode.null ())
        |> BackendTask.allowFatal


{-| Copy text to the clipboard.

    Kit.copy "Text to copy"

-}
copy : String -> BackendTask FatalError ()
copy text =
    BackendTask.Custom.run "scriptKitCopy"
        (Encode.string text)
        (Decode.null ())
        |> BackendTask.allowFatal



-- ENCODERS


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


script : BackendTask FatalError () -> Script.Script
script main =
    Script.withoutCliOptions
        (main
            |> BackendTask.quiet
        )
