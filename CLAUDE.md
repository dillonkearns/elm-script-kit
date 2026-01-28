# CLAUDE.md - elm-pages-script Architecture Guide

## Overview

**elm-pages-script** is a proof-of-concept Elm-based ScriptKit engine. It's an unpublished starter repository (not a package) that enables writing native macOS automation scripts in Elm using elm-pages Scripts (with `BackendTask` at the core, and `custom-backend-task` to letting you build a bridge to NodeJS and access the kit APIs so you can easily write wrapper functions). Scripts are compiled to JavaScript bundles compatible with ScriptKit.

The unpublished Elm API is written in `kit/`, but importantly much of that API depends on `custom-backend-task` definitions written in NodeJS.

## Principles and Goals

A primary goal of the Elm API in `kit/` is to be very "Elm-y", *not* just a direct port of the Kit APIs.

### Make Impossible States Impossible

Use Elm's type system to prevent invalid combinations at compile time:

- **`Kit.Field.min`/`max` only work on Int fields**: The signature `min : Int -> FieldConfig Int -> FieldConfig Int` means you physically cannot call `min` on a text field—the compiler rejects it.
- **`Kit.Html` uses `Html.String.Html Never`**: The `Never` type parameter means this HTML can never produce messages/events, which is correct since ScriptKit display is one-way output.
- **`Kit.Field.with` enforces correct field order**: The applicative builder pattern `with : FieldConfig a -> Fields (a -> b) -> Fields b` ensures fields are added in the exact order matching your record constructor—mismatches are compile errors.

### Use Types to Prevent Undesirable Use

Design APIs so the type system guides users toward correct usage:

- **`Kit.Db` requires a `Codec`**: You cannot store data without explicitly defining serialization. Schema changes are caught with clear error messages ("Serializer out of date") rather than silent data corruption.
- **`Choice` is a structured record**: Rather than accepting raw JS objects, `Kit.arg` takes `{ name, value, description, img }` records—typos in field names are compile errors.
- **`BackendTask FatalError a` everywhere**: Consistent error handling across the entire API; no mixing of different error types or forgetting to handle failures.

### Builder Patterns Over Configuration Records

Prefer pipelines with optional modifiers over large configuration records with many `Maybe` fields:

```elm
-- Good: Builder pattern with clear defaults
Script.define { name = "My Script", task = task }
    |> Script.withDescription "Optional"
    |> Script.withShortcut "cmd+shift+m"

-- Good: Field builder with chainable modifiers
Field.int "Age" |> Field.min 0 |> Field.max 120 |> Field.required
```

This keeps required fields explicit while making optional configuration discoverable and readable.

### Opaque Types Hide Implementation Details

Use opaque types to encapsulate internal representation and prevent users from depending on implementation details:

```elm
-- In Kit.Field, these types are opaque (constructors not exposed)
type Fields a = Fields { specs : List FieldSpec, decoder : Decoder a }
type FieldConfig a = FieldConfig { spec : FieldSpec, decoder : Decoder a }
```

Users interact only through the exposed API (`fields`, `with`, `text`, `int`, etc.), not the internal record structure. This allows refactoring internals without breaking user code.

**When to use opaque types:**
- Builder types (like `Fields`, `FieldConfig`)
- Types with invariants that must be maintained
- Types where the internal structure may evolve

### Ubiquitous Domain Language

Maintain consistent terminology across documentation, function names, type names, and comments:

- **Function names describe what they do**, not the underlying JS API (e.g., `Kit.arg` not `scriptKitArg`)
- **Use standard Elm patterns**: `andThen` for sequencing, `map` for transforming, `Maybe` for optional values
- **Recognize that naming is a process**—refactor names as understanding of the domain deepens

**Example**: `Kit.env` vs `BackendTask.Env.expect`—the Kit version provides better UX (prompts user interactively for missing values) rather than just failing, so the name reflects behavior users care about.

### Examples-Driven API Design

Design the API by writing realistic examples first, before finalizing function signatures:

1. Write concrete examples of how you *want* the API to look
2. Ask: Is this intuitive? Can invalid states be expressed? Is functionality discoverable?
3. Iterate on the API until examples read naturally

The scripts in `src/` serve as living examples—if adding a new Kit feature, write a script using it first to validate the API feels right.

### Compose with BackendTask

Everything returns `BackendTask FatalError a` enabling standard composition:

```elm
task =
    Kit.input "Enter name"
        |> BackendTask.andThen (\name ->
            Kit.notify ("Hello, " ++ name ++ "!")
        )
```

This integrates seamlessly with elm-pages' HTTP, file system, and other BackendTask APIs.

## Project Structure

```
elm-pages-script/
├── kit/                           # Library modules (Kit.* namespace)
│   ├── Kit.elm                    # Main API (input, display, clipboard, etc.)
│   └── Kit/
│       ├── Build.elm              # Build orchestration script
│       ├── Script.elm             # Script definition API (builder pattern)
│       ├── Field.elm              # Type-safe multi-field form builder
│       └── Db.elm                 # Persistent storage with elm-serialize
│
├── src/                           # User scripts
│   ├── ElmPackageSearch.elm       # Example: HTTP, selection, clipboard
│   ├── ColorPicker.elm            # Example: forms, styled HTML display
│   ├── JazzStandards.elm          # Example: Spotify API, caching
│   └── Repo.elm                   # Example: file globbing, shell commands
│
├── gen/                           # Generated temp files (auto-cleaned)
├── custom-backend-task.ts         # TypeScript bridge to ScriptKit globals
└── *.bundle.js                    # Compiled Elm bundles (~120KB each)
```

## How It Works

### Build Pipeline

Build a script with:
```bash
elm-pages run kit/Kit/Build.elm -- ModuleName
```

**Two-pass process:**
1. **Metadata extraction**: Generates temp module to read script name/description/shortcut
2. **Bundle generation**: Compiles Elm to JS bundle, creates wrapper in `~/.kenv/scripts/`

### Execution Flow

```
ScriptKit menu → ~/.kenv/scripts/my-script.js (thin wrapper)
    → imports elm-pages-script/my-script.bundle.js
    → Elm BackendTask.Custom.run calls
    → custom-backend-task.ts handlers
    → ScriptKit globals (arg, div, notify, etc.)
```

### Two-File Architecture

ScriptKit scans `~/.kenv/scripts/*.js` for scripts. Files with top-level `await` (like elm-pages bundles) would hang the scanner. Solution:
- **Thin wrapper** in `~/.kenv/scripts/` - minimal, safe to scan
- **Bundle** in project folder - loaded dynamically at runtime

## Writing Scripts

### Script Template

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
        |> Script.withDescription "Optional description"
        |> Script.withShortcut "cmd+shift+m"

task : BackendTask FatalError ()
task =
    Kit.notify "Hello from Elm!"
```

### Kit API

**User Input:**
- `Kit.arg` - Select from choices with descriptions/images
- `Kit.input` - Free text entry
- `Kit.editor` - Monaco editor with syntax highlighting
- `Kit.template` - Tab-through placeholders

**Display:**
- `Kit.div` - Display HTML (use Html.String)
- `Kit.md` - Render markdown

**Utilities:**
- `Kit.notify` - System notification
- `Kit.say` - Text-to-speech
- `Kit.copy` / `Kit.paste` - Clipboard
- `Kit.open` - Open URLs/file paths
- `Kit.env` - Environment variables

**File Selection:**
- `Kit.selectFile` / `Kit.selectFolder` - Native picker dialogs

**Text Manipulation:**
- `Kit.getSelectedText` / `Kit.setSelectedText` - System-wide text selection

### Type-Safe Forms (Kit.Field)

```elm
type alias Person = { name : String, age : Int }

task =
    Field.fields Person
        |> Field.with (Field.text "Name" |> Field.required)
        |> Field.with (Field.int "Age" |> Field.min 0)
        |> Field.runFields
        |> BackendTask.andThen (\person -> ...)
```

### Persistent Storage (Kit.Db)

```elm
-- Cache-or-fetch pattern
Kit.Db.getOrFetch "cache-name"
    (Serialize.list itemCodec)
    fetchFromApi

-- Direct operations
Kit.Db.get "name" codec
Kit.Db.write "name" codec value
Kit.Db.clear "name"
```

Storage location: `~/.kenv/db/{name}.json`

## Adding Custom Backend Tasks

1. Add handler in `custom-backend-task.ts`:
```typescript
export async function myCustomHandler(args: MyArgs): Promise<MyResult> {
    // Call ScriptKit APIs or other Node.js code
    return result;
}
```

2. Call from Elm:
```elm
BackendTask.Custom.run "myCustomHandler"
    (Encode.object [...])
    myDecoder
    |> BackendTask.allowFatal
```

## Key Dependencies

- **elm-pages** 10.2.2 - Script runner and bundler
- **elm-serialize** 1.3.1 - Type-safe codecs for persistence
- **elm-html-string** 2.0.2 - Typed HTML generation

## Bundle Optimization

Bundles use `--external` flags to exclude packages available in ScriptKit's Node.js environment, reducing size from ~1.1MB to ~120KB.

## Commands

```bash
# Build a script
elm-pages run kit/Kit/Build.elm -- ScriptName

# View documentation locally
npm run docs

# Install dependencies
npm install
```

## Output Locations

- Bundles: `./script-name.bundle.js`
- Wrappers: `~/.kenv/scripts/script-name.js`
- Database: `~/.kenv/db/{name}.json`
