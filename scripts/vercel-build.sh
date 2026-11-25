#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

flutter_version=3.47.9
flutter_sha256=25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a
cache_dir="$PWD/node_modules/.cache/clock-it"
flutter_dir="$cache_dir/flutter-$flutter_version"
flutter="$flutter_dir/bin/flutter"
export PUB_CACHE="$cache_dir/pub"
export FLUTTER_SUPPRESS_ANALYTICS=true

download_checked() {
  local url=$1 file=$2 sha256=$3
  if [[ ! -f "$file" ]] || ! printf '%s  %s\n' "$sha256" "$file" | sha256sum --check --status; then
    curl --fail --silent --show-error --location --retry 3 --output "$file.download" "$url"
    printf '%s  %s\n' "$sha256" "$file.download" | sha256sum --check
    mv -- "$file.download" "$file"
  fi
}

copy_fallback_fonts() {
  local output="$PWD/build/web/font-fallbacks"
  local noto="$cache_dir/font-fallbacks.zip"

  # Flutter bundles Roboto with --no-web-resources-cdn. Match the pinned SDK's Noto fallback table.
  download_checked 'https://chrome-infra-packages.appspot.com/dl/flutter/flutter_font_fallbacks/+/44bd38be0bc8c189a397ca6dd6f737746a9e0c6117b96a8f84f1edf6acd1206b' \
    "$noto" 7dfb35718596d45cf31b442bc33e313fde4987a2037d6765405170782e0da83c
  mkdir -p "$output"
  unzip -oq "$noto" 'LICENSE.txt' '*.woff2' -d "$output"
}

case "${1:-}" in
  install)
    if [[ ! -x "$flutter" || ! -f "$flutter_dir/.git/HEAD" ]]; then
      mkdir -p "$cache_dir"
      staging_dir=$(mktemp -d "$cache_dir/install.XXXXXXXX")
      trap 'rm -rf -- "$staging_dir"' EXIT
      archive="$staging_dir/flutter.tar.xz"
      curl --fail --silent --show-error --location --retry 3 --output "$archive" \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutter_version}-stable.tar.xz"
      printf '%s  %s\n' "$flutter_sha256" "$archive" | sha256sum --check
      tar -xJf "$archive" -C "$staging_dir" --no-same-owner \
        --exclude='flutter/bin/cache/artifacts/engine/android-*'
      rm -rf -- "$flutter_dir"
      mv -- "$staging_dir/flutter" "$flutter_dir"
    fi
    "$flutter" pub get
    ;;
  build)
    "$flutter" build web --release --no-pub --no-web-resources-cdn
    copy_fallback_fonts
    ;;
  *)
    printf 'Usage: %s {install|build}\n' "$0" >&2
    exit 2
    ;;
esac
