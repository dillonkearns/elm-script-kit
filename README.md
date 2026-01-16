# elm-script-kit

Elm bindings for [ScriptKit](https://www.scriptkit.com/) using [elm-pages](https://elm-pages.com/) scripts.

## Goals

This is a **starter repo**, not a published package. Fork it and build your own ScriptKit scripts in Elm with type-safe UI primitives, then customize as needed.

## Getting Started

1. Create a new script in `src/`:

```elm
module MyScript exposing (run, task)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Kit
import Kit.Script as Script
import Pages.Script exposing (Script)

run : Script
run =
    Script.define
        { name = "My Script"
        , moduleName = "MyScript"
        }
        |> Script.withDescription "Does something cool"
        |> Script.build

task : BackendTask FatalError ()
task =
    Kit.input "What's your name?"
        |> BackendTask.andThen (\name -> Kit.notify ("Hello, " ++ name ++ "!"))
```

2. Build it:

```bash
elm-pages run src/MyScript.elm
```

This generates the JS wrapper and bundle automatically.

## Available APIs

**Kit** - `arg`, `input`, `editor`, `template`, `div`, `md`, `selectFile`, `selectFolder`, `notify`, `say`, `copy`, `paste`

**Kit.Field** - Type-safe form builder with `text`, `int`, `number`, `email`, `textarea` fields

**Kit.Script** - Builder for script metadata (`name`, `description`, `shortcut`)

## Local Documentation

```bash
npm install -g elm-doc-preview
elm-doc-preview
```

Then open http://localhost:8000 to browse the `Kit` and `Kit.Field` module docs.

## Future: script-kit-next

[script-kit-next](https://github.com/johnlindquist/script-kit-next) is a Rust/GPUI rewrite of ScriptKit currently in development. The core prompt APIs (`arg`, `div`, `editor`, `fields`) are compatible, but utility functions (`notify`, `copy`, `paste`) will need library wrappers. This starter repo should adapt with minimal changes.
