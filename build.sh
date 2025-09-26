#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <godotDir>"
  echo "Example: $0 /opt/godot-src"
  exit 1
}

[[ $# -eq 1 ]] || usage
godotDir="$(realpath "$1")"

if [[ ! -d "$godotDir" ]]; then
  echo "Error: Directory not found: $godotDir"
  exit 1
fi

cd "$godotDir"

# Clean previous builds
scons --clean || true
( cd platform/android/java && ./gradlew clean )

# Build Linux editor
scons platform=linuxbsd

# Build Android templates
export ANDROID_SDK_ROOT="${ANDROID_HOME:?ANDROID_HOME not set}"
scons platform=android target=template_release arch=armv7
scons platform=android target=template_release arch=arm64v8
( cd platform/android/java && ./gradlew generateGodotTemplates )

echo "Build complete. Artifacts in: ${godotDir}/bin"

