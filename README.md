# elm-script-kit

Elm bindings for [ScriptKit](https://www.scriptkit.com/) using [elm-pages scripts](https://elm-pages.com/docs/elm-pages-scripts).

## Goals

This is a **starter repo**, not a published package. Fork it and build your own ScriptKit scripts in Elm with type-safe UI primitives, then customize as needed.

This project builds heavily on [elm-pages scripts](https://elm-pages.com/docs/elm-pages-scripts) - understanding that foundation will help you get the most out of this starter.

## Example: Elm Package Search

Check out [`src/ElmPackageSearch.elm`](src/ElmPackageSearch.elm) - **122 lines of Elm** for a fully functional package search tool you can pull up with a global keyboard shortcut. Search packages, see descriptions, and copy `elm install` commands to your clipboard.

<img width="1546" height="962" alt="image" src="https://github.com/user-attachments/assets/a94ead66-50ce-4f2a-b9e3-461427fda5c8" />


## Prerequisites

1. **Install ScriptKit** from [scriptkit.com](https://www.scriptkit.com/)
2. **Clone this repo** into your ScriptKit scripts directory:
   ```bash
   cd ~/.kenv/scripts
   git clone https://github.com/dillonkearns/elm-script-kit.git elm-pages-script
   cd elm-pages-script
   ```
3. **Install dependencies**:
   ```bash
   npm install
   ```

The folder structure should be:
```
~/.kenv/scripts/
├── elm-pages-script/       # This Elm project
│   ├── kit/                # Library (Kit.* modules)
│   │   ├── Kit.elm         # ScriptKit API
│   │   └── Kit/
│   │       ├── Build.elm   # Build script
│   │       ├── Field.elm   # Form fields API
│   │       └── Script.elm  # Script definition API
│   ├── src/            # Your scripts go here
│   │   └── YourScript.elm
│   └── gen/                # Generated temp files (auto-cleaned)
├── your-script.js          # Generated JS wrappers (auto-created)
└── ...
```

## Creating a New Script

One command does everything:

```bash
cd ~/.kenv/scripts/elm-pages-script

# Create a new script (generates Elm file + JS wrapper)
elm-pages run kit/Kit/Build.elm -- MyScript

# Edit src/MyScript.elm to add your logic, then build:
elm-pages run kit/Kit/Build.elm -- MyScript
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

## Documentation

- **Online**: [View docs on elm-doc-preview](https://elm-doc-preview.netlify.app/?repo=dillonkearns/elm-script-kit)
- **Local**: Run `npm run docs` and open http://localhost:8000

## Future: script-kit-next

[script-kit-next](https://github.com/johnlindquist/script-kit-next) is a Rust/GPUI rewrite of ScriptKit currently in development. The core prompt APIs (`arg`, `div`, `editor`, `fields`) are compatible, but utility functions (`notify`, `copy`, `paste`) will need library wrappers. This starter repo should adapt with minimal changes.
