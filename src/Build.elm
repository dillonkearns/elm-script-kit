module Build exposing (run)

{-| Build script for Kit scripts.

Usage: `elm-pages run src/Build.elm -- ModuleName`

Example: `elm-pages run src/Build.elm -- ColorPicker`

This performs a two-pass build:

1.  Generates a metadata extraction script, runs it to get script metadata
2.  Generates JS wrapper and Elm harness, then bundles

-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import Cli.Option as Option
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import FatalError exposing (FatalError)
import Json.Decode as Decode
import Pages.Script as Script exposing (Script)


type alias CliOptions =
    { moduleName : String
    }


run : Script
run =
    Script.withCliOptions program
        (\{ moduleName } ->
            checkIfModuleExists moduleName
                |> BackendTask.andThen
                    (\exists ->
                        if exists then
                            buildScript moduleName

                        else
                            generateNewScript moduleName
                                |> BackendTask.andThen (\_ -> Script.log ("Created src/" ++ moduleName ++ ".elm - edit it and run this command again to build!"))
                    )
        )


checkIfModuleExists : String -> BackendTask FatalError Bool
checkIfModuleExists moduleName =
    File.rawFile ("src/" ++ moduleName ++ ".elm")
        |> BackendTask.toResult
        |> BackendTask.map
            (\result ->
                case result of
                    Ok _ ->
                        True

                    Err _ ->
                        False
            )


buildScript : String -> BackendTask FatalError ()
buildScript moduleName =
    Script.log ("Building " ++ moduleName ++ "...")
        |> BackendTask.andThen (\_ -> generateMetaScript moduleName)
        |> BackendTask.andThen (\_ -> runMetaScript)
        |> BackendTask.andThen (\_ -> readMetadata)
        |> BackendTask.andThen
            (\meta ->
                generateJsWrapper meta
                    |> BackendTask.andThen (\_ -> generateHarness moduleName)
                    |> BackendTask.andThen (\_ -> bundleHarness meta.slug)
                    |> BackendTask.andThen (\_ -> cleanup)
                    |> BackendTask.andThen (\_ -> Script.log ("Built " ++ meta.slug ++ ".bundle.js"))
            )


generateNewScript : String -> BackendTask FatalError ()
generateNewScript moduleName =
    let
        humanName =
            toHumanName moduleName

        slug =
            toSlug humanName

        elmContent =
            "module "
                ++ moduleName
                ++ """ exposing (script)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Kit
import Kit.Script as Script


script : Script.Script
script =
    Script.define
        { name = \""""
                ++ humanName
                ++ """\"
        , task = task
        }
        |> Script.withDescription "TODO: Add description"


task : BackendTask FatalError ()
task =
    Kit.notify "Hello from """
                ++ moduleName
                ++ """!"
"""

        jsContent =
            [ "// Name: " ++ humanName
            , "// Description: TODO: Add description"
            , ""
            , "import \"@johnlindquist/kit\""
            , ""
            , "await import(\"./elm-pages-script/" ++ slug ++ ".bundle.js\")"
            ]
                |> String.join "\n"
    in
    Script.writeFile
        { path = "src/" ++ moduleName ++ ".elm"
        , body = elmContent
        }
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\_ ->
                Script.writeFile
                    { path = "../" ++ slug ++ ".js"
                    , body = jsContent
                    }
                    |> BackendTask.allowFatal
            )


toHumanName : String -> String
toHumanName moduleName =
    moduleName
        |> String.toList
        |> List.foldl
            (\char acc ->
                if Char.isUpper char && acc /= "" then
                    acc ++ " " ++ String.fromChar char

                else
                    acc ++ String.fromChar char
            )
            ""


program : Program.Config CliOptions
program =
    Program.config
        |> Program.add
            (OptionsParser.build CliOptions
                |> OptionsParser.with
                    (Option.requiredPositionalArg "ModuleName")
            )


type alias Metadata =
    { name : String
    , slug : String
    , description : Maybe String
    , shortcut : Maybe String
    }


generateMetaScript : String -> BackendTask FatalError ()
generateMetaScript moduleName =
    let
        content =
            """module KitMeta exposing (run)

import BackendTask
import Json.Encode as Encode
import Pages.Script as Script exposing (Script)
import """ ++ moduleName ++ """


run : Script
run =
    Script.withoutCliOptions
        (Script.writeFile
            { path = "kit-meta.json"
            , body =
                Encode.encode 0
                    (Encode.object
                        [ ( "name", Encode.string """ ++ moduleName ++ """.script.name )
                        , ( "description"
                          , """ ++ moduleName ++ """.script.description
                                |> Maybe.map Encode.string
                                |> Maybe.withDefault Encode.null
                          )
                        , ( "shortcut"
                          , """ ++ moduleName ++ """.script.shortcut
                                |> Maybe.map Encode.string
                                |> Maybe.withDefault Encode.null
                          )
                        ]
                    )
            }
            |> BackendTask.allowFatal
        )
"""
    in
    Script.writeFile
        { path = "src/KitMeta.elm"
        , body = content
        }
        |> BackendTask.allowFatal


runMetaScript : BackendTask FatalError ()
runMetaScript =
    Script.command "npx" [ "elm-pages", "run", "src/KitMeta.elm" ]
        |> BackendTask.quiet
        |> BackendTask.map (\_ -> ())


readMetadata : BackendTask FatalError Metadata
readMetadata =
    File.jsonFile metadataDecoder "kit-meta.json"
        |> BackendTask.allowFatal


metadataDecoder : Decode.Decoder Metadata
metadataDecoder =
    Decode.map4
        (\name description shortcut slug ->
            { name = name
            , slug = slug
            , description = description
            , shortcut = shortcut
            }
        )
        (Decode.field "name" Decode.string)
        (Decode.field "description" (Decode.nullable Decode.string))
        (Decode.field "shortcut" (Decode.nullable Decode.string))
        (Decode.field "name" Decode.string |> Decode.map toSlug)


toSlug : String -> String
toSlug name =
    name
        |> String.toLower
        |> String.words
        |> String.join "-"


generateJsWrapper : Metadata -> BackendTask FatalError ()
generateJsWrapper meta =
    let
        lines =
            [ Just ("// Name: " ++ meta.name)
            , meta.description |> Maybe.map (\d -> "// Description: " ++ d)
            , meta.shortcut |> Maybe.map (\s -> "// Shortcut: " ++ s)
            , Just ""
            , Just "import \"@johnlindquist/kit\""
            , Just ""
            , Just ("await import(\"./elm-pages-script/" ++ meta.slug ++ ".bundle.js\")")
            ]

        content =
            lines
                |> List.filterMap identity
                |> String.join "\n"
    in
    Script.writeFile
        { path = "../" ++ meta.slug ++ ".js"
        , body = content
        }
        |> BackendTask.allowFatal


generateHarness : String -> BackendTask FatalError ()
generateHarness moduleName =
    let
        content =
            """module KitHarness exposing (run)

import BackendTask
import Pages.Script as Script exposing (Script)
import """ ++ moduleName ++ """


run : Script
run =
    Script.withoutCliOptions
        (""" ++ moduleName ++ """.script.task
            |> BackendTask.quiet
        )
"""
    in
    Script.writeFile
        { path = "src/KitHarness.elm"
        , body = content
        }
        |> BackendTask.allowFatal


bundleHarness : String -> BackendTask FatalError ()
bundleHarness slug =
    Script.command "npx"
        [ "elm-pages"
        , "bundle-script"
        , "src/KitHarness.elm"
        , "--output"
        , slug ++ ".bundle.js"
        , "--external"
        , "make-fetch-happen"
        , "--external"
        , "globby"
        , "--external"
        , "gray-matter"
        , "--external"
        , "cross-spawn"
        , "--external"
        , "which"
        , "--external"
        , "micromatch"
        , "--external"
        , "@johnlindquist/kit"
        ]
        |> BackendTask.quiet
        |> BackendTask.map (\_ -> ())


cleanup : BackendTask FatalError ()
cleanup =
    Script.command "rm" [ "-f", "src/KitMeta.elm", "src/KitHarness.elm", "kit-meta.json" ]
        |> BackendTask.quiet
        |> BackendTask.map (\_ -> ())
