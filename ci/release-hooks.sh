#!/usr/bin/env bash
#
# bc's half of dull-nix's mkReleaseCommand: what a release of this repository
# publishes. All four hooks must be answered -- one falling through to the
# usage arm is a publish guard that silently does not run.
#
# `image` is not one of the four. release.yml calls it so the guard and the
# publish read the same string.
set -euo pipefail

readonly published_image=ghcr.io/byte-club-yyc/bc

refuse() {
  if [[ ${GITHUB_ACTIONS-} == true ]]; then
    printf '::error::%s\n' "$*" >&2
  else
    printf 'refusing to release: %s\n' "$*" >&2
  fi
  return 1
}

assert_ready() {
  command -v skopeo >/dev/null 2>&1 || command -v nix >/dev/null 2>&1 \
    || refuse 'neither skopeo nor nix is on PATH, and one of them is what asks ghcr.io whether this version is already published'
  command -v release-guards >/dev/null 2>&1 \
    || refuse 'release-guards is not on PATH, and it is what tells describe whether :latest moves'
}

assert_unpublished() {
  local version=${1-} reference="docker://$published_image:${1#v}" output status=0
  local -a skopeo=(skopeo) authfile=()
  # Fallback for a bare checkout; both callers put skopeo on PATH first.
  command -v skopeo >/dev/null 2>&1 || skopeo=(nix run nixpkgs#skopeo --)
  if [[ -n ${GHCR_AUTHFILE-} ]]; then authfile=(--authfile "$GHCR_AUTHFILE"); fi

  # Order matters: stderr into the capture, then stdout discarded.
  output=$("${skopeo[@]}" inspect --no-tags "${authfile[@]}" "$reference" 2>&1 >/dev/null) || status=$?

  ((status != 0)) || refuse "$published_image:${version#v} is already published -- one version string names one artifact forever; release the next version instead"

  # Fails closed: only an answer naming an actual absence counts as
  # unpublished. A 401 or an unreachable registry is not permission to publish.
  case $output in
    *'manifest unknown'* | *'name unknown'*) return 0 ;;
  esac
  refuse "could not establish whether $published_image:${version#v} exists; skopeo said: $output -- if that reads as an authentication failure, run 'skopeo login ghcr.io', or point GHCR_AUTHFILE at an existing auth file"
}

describe() {
  local version=${1-} latest
  # Repeated from assert_ready: a direct caller skips that step and would get a
  # confidently wrong :latest.
  command -v release-guards >/dev/null 2>&1 \
    || refuse 'release-guards is not on PATH, and it is what tells describe whether :latest moves'
  if release-guards is-stable "$version"; then
    latest="moves to $version"
  else
    latest="unchanged -- $version is a prerelease"
  fi
  # %-9s matches release's own commit/version rows.
  printf '%-9s %s:%s\n' image "$published_image" "${version#v}"
  printf '%-9s %s\n' ':latest' "$latest"
}

set_version() {
  # Both gleam.toml versions are unread placeholders, so the release commit
  # carries CHANGELOG.md alone.
  :
}

case ${1-} in
  assert-ready) assert_ready ;;
  assert-unpublished) assert_unpublished "${2-}" ;;
  describe) describe "${2-}" ;;
  set-version) set_version "${2-}" ;;
  image) printf '%s\n' "$published_image" ;;
  *)
    printf 'usage: release-hooks {assert-ready|assert-unpublished|describe|set-version|image} ARGUMENT\n' >&2
    exit 2
    ;;
esac
