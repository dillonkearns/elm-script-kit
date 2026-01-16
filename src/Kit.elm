module Kit exposing
    ( arg, input, editor, template, Choice, ArgOptions
    , div, md, Html
    , selectFile, selectFolder
    , notify, say, copy, paste
    , script
    )

{-| Elm bindings for ScriptKit.


# User Input

@docs arg, input, editor, template, Choice, ArgOptions


# Display

@docs div, md, Html


# File Picking

@docs selectFile, selectFolder


# Utilities

@docs notify, say, copy, paste


# Script Helper

@docs script

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


{-| Template input with tab-through placeholders.

    -- Simple placeholders
    Kit.template "Hello $1, welcome to $2!"

    -- Placeholders with defaults
    Kit.template "Hello ${1:name}, welcome to ${2:place}!"

Users can tab between placeholders to fill them in.

-}
template : String -> BackendTask FatalError String
template templateString =
    BackendTask.Custom.run "scriptKitTemplate"
        (Encode.string templateString)
        Decode.string
        |> BackendTask.allowFatal



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


{-| Convert markdown to HTML string for use with div.

    Kit.md "# Hello\n\nThis is **bold**"
        |> BackendTask.andThen
            (\htmlString ->
                Kit.div (Html.div [] [ Html.text htmlString ])
            )

Returns an HTML string that can be embedded in div output.

-}
md : String -> BackendTask FatalError String
md markdown =
    BackendTask.Custom.run "scriptKitMd"
        (Encode.string markdown)
        Decode.string
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


{-| Get text from the clipboard.

    Kit.paste
        |> BackendTask.andThen
            (\clipboardText ->
                -- do something with clipboardText
            )

-}
paste : BackendTask FatalError String
paste =
    BackendTask.Custom.run "scriptKitPaste"
        Encode.null
        Decode.string
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


{-| Define a top-level script (like elm-pages `Script.withoutCliOptions`).
-}
script : BackendTask FatalError () -> Script.Script
script main =
    Script.withoutCliOptions
        (main
            |> BackendTask.quiet
        )
