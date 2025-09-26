#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <godotDir> <newVersion>"
  echo "Example: $0 /opt/godot-src 4.2.3"
  exit 1
}

[[ $# -eq 2 ]] || usage
godotDir="$(realpath "$1")"
newVersion="$2"

# Full and short commit hashes
commitHash="$(git -C "$godotDir" rev-parse HEAD)"
commitHashShort="$(printf "%s" "$commitHash" | cut -c1-7)"

# Ensure tag == newVersion exists and points to this commit; create if missing
existingTagForCommit="$(git -C "$godotDir" tag --points-at "$commitHash" | grep -Fx "$newVersion" || true)"
if [[ -z "$existingTagForCommit" ]]; then
  echo "No existing tag for this commit. Creating tag '${newVersion}'..."
  git -C "$godotDir" tag -f "$newVersion" "$commitHash"
  git -C "$godotDir" push -f origin "$newVersion"
fi
releaseTag="$newVersion"

binDir="${godotDir}/bin"
[[ -d "$binDir" ]] || { echo "Error: ${binDir} does not exist"; exit 1; }

assets=("$binDir"/*)
if [[ ! -e "${assets[0]}" ]]; then
  echo "Error: No files found in ${binDir} to upload"
  exit 1
fi

releaseTitle="ShipThis Godot ${newVersion} Build ${commitHashShort}"
releaseNotes="Release for ${newVersion} (${commitHashShort}). Includes Linux editor and Android export templates."

echo "Creating GitHub release '${releaseTag}' with files:"
printf '  - %s\n' "${assets[@]}"
echo

# Do NOT pass --target; the tag already points to the commit
gh release create "${releaseTag}" "${assets[@]}" \
  --title "${releaseTitle}" \
  --notes "${releaseNotes}"

echo "Published release:"
echo "  tag:    ${releaseTag}"
echo "  title:  ${releaseTitle}"
echo "  commit: ${commitHashShort}"

