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
    "$flutter" build web --release --no-pub
    ;;
  *)
    printf 'Usage: %s {install|build}\n' "$0" >&2
    exit 2
    ;;
esac
