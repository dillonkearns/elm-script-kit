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
