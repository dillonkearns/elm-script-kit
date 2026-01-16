# elm-pages + ScriptKit Integration Notes

## Current API (Kit.elm)

### User Input
- `arg` - select from choices
- `input` - free text input
- `editor` - Monaco editor with syntax highlighting
- `template` - tab-through placeholder substitution (`$1`, `${2:default}`)
- `fields` builder (Kit.Field) - type-safe multi-field forms

### Display
- `div` - display HTML (with `Html.String` for typed HTML)
- `md` - convert markdown to HTML string

### File Picking
- `selectFile` - native Finder file picker
- `selectFolder` - native Finder folder picker

### Utilities
- `notify` - system notifications
- `say` - text-to-speech
- `copy` - copy to clipboard
- `paste` - get clipboard contents

## Deferred Features

These features are planned but deferred for now:

### Richer Choice type for arg
Currently `Choice` is `{ name : String, value : String }`. Could add:
- `description` - secondary text
- `preview` - HTML preview pane
- `shortcut` - keyboard shortcuts (e.g., `[O]pen` triggers on `o` key)

### drop
Drag and drop support. Returns either text or file path. Need to design how to handle the union type in Elm cleanly.

### hotkey
Capture key combinations. Lower priority for now.

## Known Issues

### ScriptKit fields() select bug
ScriptKit's `fields()` function has a bug where `select` elements don't render their options - the dropdown appears empty. This is a ScriptKit issue, not our code. We've removed `select` from the Kit.Field API; use `Kit.arg` for selection instead.

## Future Possibilities

### arg enhancements
- Dynamic/async choices
- Preview pane for choices

### div enhancements
- `divWithSubmit` - return values via `[Accept](submit:yes)` links
- Widget API for persistent windows

### Additional inputs
- `path` - filesystem browser with tab navigation

### AI functions
- `ai` - text generation
- `ai.object` - structured output with schema validation
- `assistant` - stateful conversation

## Bundle Size

The default `elm-pages bundle-script` output is ~1.1MB due to bundled dependencies:
- `make-fetch-happen` (~400-500KB) - npm's HTTP client with caching, proxy support, etc.
- `globby`, `gray-matter`, `cross-spawn`, `which`, `micromatch`

Using `--external` flags reduces bundle to ~120KB:

```bash
npx elm-pages bundle-script src/ColorPicker.elm \
  --output color-picker.bundle.js \
  --external make-fetch-happen \
  --external globby \
  --external gray-matter \
  --external cross-spawn \
  --external which \
  --external micromatch \
  --external "@johnlindquist/kit"
```

## ScriptKit Scanning Issue

ScriptKit hangs when scanning `.js` files that execute on import. The elm-pages bundle has top-level `await` that runs immediately.

**Solution:** Two-file approach:
1. Thin wrapper in `scripts/` folder (ScriptKit scans this)
2. Bundle in subfolder (not scanned)

## Wrapper Script Requirements

The wrapper MUST have `import "@johnlindquist/kit"` to initialize ScriptKit environment (including Tailwind CSS):

```js
// Name: Elm Color Picker
// Description: Pick a color using elm-pages

import "@johnlindquist/kit"

await import("./elm-pages-script/color-picker.bundle.js")
```

Without this import, Tailwind classes won't work in `div()` output.

## custom-backend-task.ts

ScriptKit globals (`arg`, `div`, `md`) are available at runtime. The kit import here is optional (just helps TypeScript):

```ts
import "@johnlindquist/kit"

export async function scriptKitArg(options: ArgOptions): Promise<string> {
  return await arg({
    placeholder: options.placeholder,
    choices: options.choices,
  });
}

export async function scriptKitDiv(htmlContent: string): Promise<null> {
  await div(htmlContent);
  return null;
}
```

## Elm API (Kit.elm)

Clean Elm bindings using `BackendTask.Custom`:
- `Kit.arg` - prompt user to select from choices
- `Kit.div` - display HTML (uses `zwilias/elm-html-string` for typed HTML)

## File Structure

```
scripts/
├── elm-color.js                    # Thin wrapper (ScriptKit entry point)
└── elm-pages-script/
    ├── src/
    │   ├── Kit.elm                 # Elm ScriptKit API
    │   └── ColorPicker.elm         # Example script
    ├── custom-backend-task.ts      # JS bridge to ScriptKit
    ├── build-scriptkit.sh          # Build with externals
    └── color-picker.bundle.js      # Compiled output (~120KB)
```
