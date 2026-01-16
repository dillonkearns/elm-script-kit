# elm-pages + ScriptKit Integration Notes

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
