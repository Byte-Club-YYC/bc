{ pkgs, config, ... }:

{
  # The devenv environment itself; build artifacts go through the flake's
  # nixConfig and warm-cache.
  cachix.enable = true;
  cachix.pull = [ "dull-ca" ];
  cachix.push = "dull-ca";

  packages = with pkgs; [
    # Minimal erlang, as in flake.nix -- the full build drags in GTK and webkit.
    gleam
    beam_minimal.interpreters.erlang_27
    rebar3
    esbuild
    nodejs
    lefthook

    # cachix.enable configures the cache but ships no binary. The rest are for
    # `release`.
    cachix
    gh
    git-cliff
    skopeo
  ];

  # What build-client writes to, so run-server serves the last build.
  env.STATIC_DIRECTORY = "${config.devenv.root}/client/priv/static";

  scripts = {
    build-client.exec = ''
      set -euo pipefail
      cd "$DEVENV_ROOT/client"
      gleam build --target javascript
      "$DEVENV_ROOT/ci/build-client.sh" build/dev/javascript priv/static
    '';

    run-server.exec = ''
      set -euo pipefail
      cd "$DEVENV_ROOT/server"
      gleam run
    '';

    # Not `test`: that is a shell builtin, so the script would be unreachable.
    run-tests.exec = ''
      set -euo pipefail
      cd "$DEVENV_ROOT/client" && gleam test
      cd "$DEVENV_ROOT/server" && gleam test
    '';

    format.exec = ''
      set -euo pipefail
      cd "$DEVENV_ROOT/client" && gleam format src test
      cd "$DEVENV_ROOT/server" && gleam format src test
    '';

    # The same gate CI runs.
    gate.exec = ''cd "$DEVENV_ROOT" && exec nix flake check --print-build-logs "$@"'';
  };

  # The server reads the bundle from disk per request, so a rebuild needs only a
  # browser reload.
  processes = {
    server.exec = ''
      set -euo pipefail
      build-client
      run-server
    '';
    client.exec = ''
      set -euo pipefail
      cd "$DEVENV_ROOT/client"
      exec ${pkgs.watchexec}/bin/watchexec \
        --watch src \
        --exts gleam,mjs \
        --restart \
        -- build-client
    '';
  };

  # Runs the gate and pushes every output to cachix, so CI finds them built.
  #
  # NOTE: `cachix push` marks a rejected push with a red x and still exits 0,
  # hence the verification below. Nix caches a "not in this cache" answer for an
  # hour, hence the zeroed negative TTL.
  scripts.warm-cache.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"
    cachixConfig="''${XDG_CONFIG_HOME:-$HOME/.config}/cachix/cachix.dhall"
    if [ -z "''${CACHIX_AUTH_TOKEN:-}" ] && [ ! -f "$cachixConfig" ]; then
      {
        echo "warm-cache: no cachix auth token — every push would silently no-op."
        echo
        echo "Mint a write token for the dull-ca cache at"
        echo "    https://app.cachix.org/cache/dull-ca/settings/authtokens"
        echo "then store it once:"
        echo
        echo "    cachix authtoken <token>"
        echo "    (writes $cachixConfig)"
        echo
        echo "or export it for this shell only (nushell):"
        echo
        echo '    $env.CACHIX_AUTH_TOKEN = "<token>"'
      } >&2
      exit 1
    fi
    nix flake check --print-build-logs

    gateOutputs=$(nix eval --raw '.#checks.x86_64-linux' --apply \
      'checks: builtins.concatStringsSep "\n" (map (c: c.outPath) (builtins.attrValues checks))')

    # By path, not `cachix watch-exec`: that only pushes what the wrapped
    # command adds to the store, so a second run would push nothing silently.
    echo "$gateOutputs" | cachix push dull-ca

    unpushed=""
    for path in $gateOutputs; do
      if ! nix path-info --store https://dull-ca.cachix.org \
        --narinfo-cache-negative-ttl 0 "$path" >/dev/null 2>&1; then
        unpushed="$unpushed  $path"$'\n'
      fi
    done

    if [ -n "$unpushed" ]; then
      {
        echo "warm-cache: the gate passed, but these outputs never reached dull-ca:"
        printf '%s' "$unpushed"
        echo "cachix marks a rejected push with a red x and still exits 0, so scroll up."
        echo "The usual cause is a token without write access to dull-ca; check with:"
        echo "    cachix push dull-ca <one of the paths above>"
      } >&2
      exit 1
    fi

    echo "warm-cache: gate passed, every output is in dull-ca — the gate runs on CI as cache hits."
  '';

  # Via `nix run`: devenv resolves its own scripts first, so a bare
  # `exec release` would recurse into this one.
  scripts.release.exec = ''cd "$DEVENV_ROOT" && exec nix run "$DEVENV_ROOT#release" -- "$@"'';
}
