#!/bin/bash
set -o physical -o errtrace -o errexit -o nounset -o pipefail
shopt -s failglob

# See:
# https://github.com/microsoft/vscode/blob/3728d519bdd2e62aef588e2478e349e1e62f3b14/build/gulpfile.vscode.js#L454-L464
# https://github.com/VSCodium/vscodium/blob/master/build.sh

yarn monaco-compile-check
yarn valid-layers-check

yarn gulp vscode-min
rmtrash out-app
mv ../VSCode-darwin-arm64 out-app

# product.overrides.json gets updated by rebase-latest.sh
# It doesn't get used in release mode (when VSCODE_DEV isn't set), so we overwrite product.json
appDir="out-app/Code - OSS.app/Contents/Resources/app"
mv "$appDir/product.json" "$appDir/product.json.orig"
cp product.overrides.json "$appDir/product.json"
