module Kit.Script exposing
    ( Script
    , define
    , withDescription
    , withShortcut
    )

{-| Define ScriptKit scripts with a simple record type.

    module ColorPicker exposing (script)

    import Kit.Script as Script

    script : Script.Script
    script =
        Script.define
            { name = "Color Picker"
            , task =
                Kit.input "Pick a color"
                    |> BackendTask.andThen ...
            }
            |> Script.withDescription "Pick a color"
            |> Script.withShortcut "cmd+shift+c"

Then build with: `elm-pages run src/Build.elm -- ColorPicker`


# Defining Scripts

@docs Script, define, withDescription, withShortcut

-}

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)


{-| A ScriptKit script definition. This is a plain record that holds:

  - `name` - Display name in ScriptKit
  - `description` - Optional description
  - `shortcut` - Optional keyboard shortcut
  - `task` - The actual script logic as a BackendTask

-}
type alias Script =
    { name : String
    , description : Maybe String
    , shortcut : Maybe String
    , task : BackendTask FatalError ()
    }


{-| Define a script with required fields.

    Script.define
        { name = "My Script"
        , task = Kit.notify "Hello!"
        }

-}
define : { name : String, task : BackendTask FatalError () } -> Script
define { name, task } =
    { name = name
    , description = Nothing
    , shortcut = Nothing
    , task = task
    }


{-| Add a description to the script.

    Script.define { ... }
        |> Script.withDescription "Does something cool"

-}
withDescription : String -> Script -> Script
withDescription desc script =
    { script | description = Just desc }


{-| Add a keyboard shortcut to the script.

    Script.define { ... }
        |> Script.withShortcut "cmd+shift+m"

-}
withShortcut : String -> Script -> Script
withShortcut shortcut script =
    { script | shortcut = Just shortcut }
