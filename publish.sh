#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <godotDir> <newVersion>"
  echo "Example: $0 /opt/godot-src 4.1.5"
  exit 1
}

[[ $# -eq 2 ]] || usage
godotDir="$(realpath "$1")"
newVersion="$2"

commitHash="$(git -C "$godotDir" rev-parse --short HEAD)"

binDir="${godotDir}/bin"
[[ -d "$binDir" ]] || { echo "Error: ${binDir} does not exist"; exit 1; }

assets=("$binDir"/*)
if [[ ! -e "${assets[0]}" ]]; then
  echo "Error: No files found in ${binDir} to upload"
  exit 1
fi

releaseTag="${newVersion}-${commitHash}-sc"
releaseTitle="ShipThis Godot ${newVersion} Build ${commitHash}"
releaseNotes="Automated release for ${newVersion} (${commitHash}). Includes Linux editor and Android export templates."

echo "Creating GitHub release '${releaseTag}' with files:"
printf '  - %s\n' "${assets[@]}"
echo

gh release create "${releaseTag}" "${assets[@]}" \
  --title "${releaseTitle}" \
  --notes "${releaseNotes}"

echo "Published release:"
echo "  tag:   ${releaseTag}"
echo "  title: ${releaseTitle}"

