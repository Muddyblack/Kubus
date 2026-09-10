#!/usr/bin/env bash
# Point the Nix package at a Kubus release.
#
#   nix/update.sh            # latest v* tag on the upstream repository
#   nix/update.sh v0.8.1     # a specific release
#
# Rewrites version and hash in nix/kubus/package.nix. Run it after a release is
# published (the AppImage has to exist) and commit the result; the Nix CI job
# then builds it and pushes the closure to the binary cache.
set -euo pipefail

repo="https://github.com/FloSch62/Kubus"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package="$here/kubus/package.nix"

for tool in nix-prefetch-url nix; do
  command -v "$tool" >/dev/null || { echo "$tool is required (install Nix)" >&2; exit 1; }
done

tag="${1:-}"
if [ -z "$tag" ]; then
  # Highest v* tag by version sort, ignoring the peeled ^{} refs.
  tag="$(git ls-remote --tags --refs "$repo" 'v*' \
    | awk -F/ '{print $NF}' \
    | sort -V \
    | tail -n1)"
fi
version="${tag#v}"
[ -n "$version" ] || { echo "could not determine a release tag" >&2; exit 1; }

url="$repo/releases/download/v$version/kubus-$version-linux-x86_64.AppImage"
echo "prefetching $url"
sri="$(nix hash to-sri --type sha256 "$(nix-prefetch-url "$url")")"

sed -i \
  -e "s|^  version = \".*\";|  version = \"$version\";|" \
  -e "s|hash = \"sha256-.*\";|hash = \"$sri\";|" \
  "$package"

echo "nix/kubus/package.nix -> $version ($sri)"
