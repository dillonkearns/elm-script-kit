module Kit.Script exposing
    ( Config
    , define
    , withDescription
    , withShortcut
    , build
    )

{-| Builder API for defining ScriptKit scripts.

    module ColorPicker exposing (run, task)

    import Kit.Script as Script

    run : Script
    run =
        Script.define
            { name = "Color Picker"
            , moduleName = "ColorPicker"
            }
            |> Script.withDescription "Pick a color"
            |> Script.withShortcut "cmd+shift+c"
            |> Script.build

    task : BackendTask FatalError ()
    task =
        Kit.input "Pick a color"
            |> BackendTask.andThen ...

Then run: `elm-pages run src/ColorPicker.elm`


# Building Scripts

@docs Config, define, withDescription, withShortcut, build

-}

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Pages.Script as Script exposing (Script)


{-| Configuration for a ScriptKit script.
-}
type Config
    = Config
        { name : String
        , moduleName : String
        , description : Maybe String
        , shortcut : Maybe String
        }


{-| Start defining a script with required options.

    Script.define
        { name = "My Script"
        , moduleName = "MyScript"
        }

-}
define : { name : String, moduleName : String } -> Config
define opts =
    Config
        { name = opts.name
        , moduleName = opts.moduleName
        , description = Nothing
        , shortcut = Nothing
        }


{-| Add a description to the script.

    Script.define { ... }
        |> Script.withDescription "Does something cool"

-}
withDescription : String -> Config -> Config
withDescription desc (Config c) =
    Config { c | description = Just desc }


{-| Add a keyboard shortcut to the script.

    Script.define { ... }
        |> Script.withShortcut "cmd+shift+m"

-}
withShortcut : String -> Config -> Config
withShortcut shortcut (Config c) =
    Config { c | shortcut = Just shortcut }


{-| Build the script. This returns an elm-pages Script that:

1.  Generates the JS wrapper file with metadata
2.  Generates a temporary Elm file that imports your task
3.  Runs elm-pages bundle-script

-}
build : Config -> Script
build (Config c) =
    Script.withoutCliOptions
        (generateWrapperJs c
            |> BackendTask.andThen (\_ -> generateTempElm c)
            |> BackendTask.andThen (\_ -> runBundleScript c)
            |> BackendTask.andThen
                (\output ->
                    Script.log ("Built " ++ toSlug c.name ++ ".bundle.js")
                )
        )


generateWrapperJs :
    { name : String
    , moduleName : String
    , description : Maybe String
    , shortcut : Maybe String
    }
    -> BackendTask FatalError ()
generateWrapperJs c =
    let
        scriptSlug =
            toSlug c.name

        jsLines =
            [ Just ("// Name: " ++ c.name)
            , c.description |> Maybe.map (\d -> "// Description: " ++ d)
            , c.shortcut |> Maybe.map (\s -> "// Shortcut: " ++ s)
            , Just ""
            , Just "import \"@johnlindquist/kit\""
            , Just ""
            , Just ("await import(\"./elm-pages-script/" ++ scriptSlug ++ ".bundle.js\")")
            ]

        jsContent =
            jsLines
                |> List.filterMap identity
                |> String.join "\n"

        jsPath =
            "../" ++ scriptSlug ++ ".js"
    in
    Script.writeFile
        { path = jsPath
        , body = jsContent
        }
        |> BackendTask.allowFatal


generateTempElm :
    { name : String
    , moduleName : String
    , description : Maybe String
    , shortcut : Maybe String
    }
    -> BackendTask FatalError ()
generateTempElm c =
    let
        elmContent =
            [ "module KitScript exposing (run)"
            , ""
            , "import " ++ c.moduleName
            , "import BackendTask"
            , "import Pages.Script as Script exposing (Script)"
            , ""
            , ""
            , "run : Script"
            , "run ="
            , "    Script.withoutCliOptions"
            , "        (" ++ c.moduleName ++ ".task"
            , "            |> BackendTask.quiet"
            , "        )"
            ]
                |> String.join "\n"
    in
    Script.writeFile
        { path = "src/KitScript.elm"
        , body = elmContent
        }
        |> BackendTask.allowFatal


runBundleScript :
    { name : String
    , moduleName : String
    , description : Maybe String
    , shortcut : Maybe String
    }
    -> BackendTask FatalError String
runBundleScript c =
    let
        scriptSlug =
            toSlug c.name
    in
    Script.command "npx"
        [ "elm-pages"
        , "bundle-script"
        , "src/KitScript.elm"
        , "--output"
        , scriptSlug ++ ".bundle.js"
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


toSlug : String -> String
toSlug name =
    name
        |> String.toLower
        |> String.words
        |> String.join "-"
