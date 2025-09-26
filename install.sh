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

IFS='.' read -r major minor patch <<<"$newVersion"
[[ "$patch" =~ ^[0-9]+$ ]] || { echo "Error: Patch '$patch' is not numeric"; exit 1; }
(( patch > 0 )) || { echo "Error: Patch version cannot be 0"; exit 1; }

originalVersion="${major}.${minor}.$((patch - 1))"
commitHash="$(git -C "$godotDir" rev-parse --short HEAD)"

binDir="${godotDir}/bin"
[[ -d "$binDir" ]] || { echo "Error: ${binDir} does not exist. Run ./build.sh first."; exit 1; }
[[ -e "$binDir"/* ]] || { echo "Error: No files found in ${binDir}. Run ./build.sh first."; exit 1; }

newGodotDir="/opt/godot/godot-${newVersion}-${commitHash}-sc"
originalGodotDir="/opt/godot/godot-${originalVersion}-sc"
templatesDir="${newGodotDir}/editor_data/export_templates/${newVersion}-${commitHash}.stable"

echo "Copying from ${originalGodotDir} to ${newGodotDir}"
cp -r "$originalGodotDir" "$newGodotDir"

mkdir -p "$templatesDir"
echo "${newVersion}.rc.custom_build" > "${templatesDir}/version.txt"

# Copy editor binary
if [[ -f "${binDir}/godot.linuxbsd.editor.x86_64" ]]; then
  cp "${binDir}/godot.linuxbsd.editor.x86_64" "${newGodotDir}/godot"
else
  echo "Warning: godot.linuxbsd.editor.x86_64 not found in ${binDir}"
fi

# Copy Android export templates
cp "${binDir}"/android_* "${templatesDir}/" 2>/dev/null || \
  echo "Warning: no android_* templates found in ${binDir}"

echo "Installed to: ${newGodotDir}"
echo "Templates: ${templatesDir}"

