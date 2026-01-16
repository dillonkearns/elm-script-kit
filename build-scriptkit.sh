#!/bin/bash
set -e

npx elm-pages bundle-script src/ColorPicker.elm \
  --output color-picker.bundle.js \
  --external make-fetch-happen \
  --external globby \
  --external gray-matter \
  --external cross-spawn \
  --external which \
  --external micromatch \
  --external "@johnlindquist/kit"

echo "Built color-picker.bundle.js ($(wc -c < color-picker.bundle.js | tr -d ' ') bytes)"

npx elm-pages bundle-script src/ElmPackageSearch.elm \
  --output elm-package-search.bundle.js \
  --external make-fetch-happen \
  --external globby \
  --external gray-matter \
  --external cross-spawn \
  --external which \
  --external micromatch \
  --external "@johnlindquist/kit"

echo "Built elm-package-search.bundle.js ($(wc -c < elm-package-search.bundle.js | tr -d ' ') bytes)"
