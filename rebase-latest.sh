#!/bin/bash
set -o physical -o errtrace -o errexit -o nounset -o pipefail
shopt -s failglob

latest_tag=$(gh api /repos/microsoft/vscode/releases/latest --jq .tag_name)
base_tag=$(git describe --tags --abbrev=0)

if [[ "$base_tag" = "$latest_tag" ]]; then
	echo "No update, latest version is still $base_tag."
	if [[ "${1:-}" != "-f" ]]; then
		echo "Run with -f to force build anyway."
		exit
	fi
	echo "Building anyway due to force mode."
fi

installed_product_json="/Applications/Visual Studio Code.app/Contents/Resources/app/product.json"
installed_version=$(jq -r .version "$installed_product_json")
if [[ "$installed_version" != "$latest_tag" ]]; then
	# We check this because we copy the latest product.json below
	echo "Installed VS Code version needs to match the latest version on github."
	echo "Installed: $installed_version"
	echo "Github: $latest_tag"
	exit 1
fi

git fetch upstream
# We start it up again below
yarn kill-watchd

echo $'\n'"***** Rebasing from $base_tag onto $latest_tag"
git rebase --onto "$latest_tag" "$base_tag"

read -rp $'\nPress enter to verify git log\n'
git log && true # ignore pipefail

read -rp $'\nIf git log looks good, press enter to run build\n'

# Copy product.json to product.overrides.json, disabling checksums
perl -pe 's|^	"checksums": \{$|	"zzchecksums": {|' "$installed_product_json" > product.overrides.json

echo $'\n***** Running yarn\n'
yarn

echo $'\n***** Running yarn compile\n'
yarn compile

echo $'\n***** Running prelaunch\n'
node build/lib/preLaunch.js

# yarn exec has issues running another yarn command, so we call deemon directly
./node_modules/deemon/src/deemon.js --detach yarn watch
