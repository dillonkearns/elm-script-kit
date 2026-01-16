# elm-script-kit

Elm bindings for [ScriptKit](https://www.scriptkit.com/) using [elm-pages](https://elm-pages.com/) scripts.

## Goals

This is a **starter repo**, not a published package. Fork it and build your own ScriptKit scripts in Elm with type-safe UI primitives, then customize as needed.

## Setup

Clone or copy this folder into your ScriptKit scripts directory:

```bash
cd ~/.kenv/scripts
git clone <this-repo> elm-pages-script
cd elm-pages-script
npm install
```

The folder structure should be:
```
~/.kenv/scripts/
├── elm-pages-script/       # This Elm project
│   ├── src/
│   │   ├── Build.elm       # Build script
│   │   ├── Kit.elm         # ScriptKit API
│   │   ├── Kit/
│   │   │   ├── Field.elm   # Form fields API
│   │   │   └── Script.elm  # Script definition API
│   │   └── YourScript.elm  # Your scripts go here
│   └── ...
├── your-script.js          # Generated JS wrappers (auto-created)
└── ...
```

## Creating a New Script

One command does everything:

```bash
cd ~/.kenv/scripts/elm-pages-script

# Create a new script (generates Elm file + JS wrapper)
elm-pages run src/Build.elm -- MyScript

# Edit src/MyScript.elm to add your logic, then build:
elm-pages run src/Build.elm -- MyScript
```

The first run creates:
- `src/MyScript.elm` - Your script with correct imports
- `~/.kenv/scripts/my-script.js` - JS wrapper for ScriptKit

The second run (after you edit) builds:
- `~/.kenv/scripts/elm-pages-script/my-script.bundle.js`

Then open ScriptKit and search for "My Script"!

## Example Script

```elm
module MyScript exposing (script)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Kit
import Kit.Script as Script


script : Script.Script
script =
    Script.define
        { name = "My Script"
        , task = task
        }
        |> Script.withDescription "Does something cool"


task : BackendTask FatalError ()
task =
    Kit.input "What's your name?"
        |> BackendTask.andThen (\name -> Kit.notify ("Hello, " ++ name ++ "!"))
```

## Available APIs

**Kit** - `arg`, `input`, `editor`, `template`, `div`, `md`, `selectFile`, `selectFolder`, `notify`, `say`, `copy`, `paste`

**Kit.Field** - Type-safe form builder with `text`, `int`, `number`, `email`, `textarea` fields

**Kit.Script** - Script definition with `define`, `withDescription`, `withShortcut`

## npm Scripts

```bash
# Build the example (Elm Package Search)
npm run build

# Start the documentation server
npm run docs
```

Open http://localhost:8000 to browse the `Kit`, `Kit.Field`, and `Kit.Script` module docs.

## Future: script-kit-next

[script-kit-next](https://github.com/johnlindquist/script-kit-next) is a Rust/GPUI rewrite of ScriptKit currently in development. The core prompt APIs (`arg`, `div`, `editor`, `fields`) are compatible, but utility functions (`notify`, `copy`, `paste`) will need library wrappers. This starter repo should adapt with minimal changes.
