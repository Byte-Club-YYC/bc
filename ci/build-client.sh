#!/usr/bin/env bash
#
# Replaces `gleam run -m lustre/dev build app`, which downloads esbuild at
# build time. Run by both flake.nix and the devenv shell, so the bundle is
# defined once.
#
# usage: build-client.sh COMPILED_JS_TREE OUTPUT_DIR
#   COMPILED_JS_TREE  output of `gleam build --target javascript`
#   OUTPUT_DIR        where client.mjs is written; must exist
set -euo pipefail

compiled=${1:?usage: build-client.sh COMPILED_JS_TREE OUTPUT_DIR}
output=${2:?usage: build-client.sh COMPILED_JS_TREE OUTPUT_DIR}

[ -d "$compiled" ] \
  || { printf 'build-client: %s does not exist\n' "$compiled" >&2; exit 1; }
[ -d "$output" ] \
  || { printf 'build-client: %s does not exist\n' "$output" >&2; exit 1; }

# Absolute: esbuild resolves the entry's import relative to $work, not cwd.
compiled=$(cd "$compiled" && pwd)
output=$(cd "$output" && pwd)

[ -f "$compiled/client/client.mjs" ] \
  || { printf 'build-client: %s holds no compiled client\n' "$compiled" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat >"$work/entry.mjs" <<ENTRY
import { main } from "$compiled/client/client.mjs";
main();
ENTRY

esbuild "$work/entry.mjs" \
  --bundle \
  --minify \
  --format=esm \
  --outfile="$output/client.mjs"
