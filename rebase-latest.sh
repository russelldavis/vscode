#!/bin/sh
set -o physical -o errtrace -o errexit -o nounset -o pipefail
shopt -s failglob

latest_tag=$(gh api /repos/microsoft/vscode/releases/latest --jq .tag_name)
base_tag=$(git describe --tags --abbrev=0)

if [[ "$base_tag" = "$latest_tag" ]]; then
	echo "No update, latest version is still $base_tag"
	if [[ "${1:-}" != "test" ]]; then
		exit
	fi
	echo "Continuing anyway for testing"
fi

git fetch upstream

echo $'\n***** Rebasing from $base_tag onto $latest_tag'
git rebase --onto "$latest_tag" "$base_tag"

read -p $'\nPress enter to verify git log\n'
git log && true # ignore pipefail

read -p $'\nIf git log looks good, press enter to run build\n'

echo $'\n***** Running yarn\n'
yarn

echo $'\n***** Running yarn compile\n'
yarn compile

echo $'\n***** Running prelaunch\n'
node build/lib/preLaunch.js
