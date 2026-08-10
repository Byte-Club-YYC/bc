{
  description = "Byte Club website — a gleam server and its lustre client, as a container";

  nixConfig = {
    extra-substituters = [ "https://dull-ca.cachix.org" ];
    extra-trusted-public-keys = [
      "dull-ca.cachix.org-1:dRCsbIU6rWu2X/4+BOxwvtyVOHUXXmRp7ZmEXwne9bk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # No nixpkgs.follows: buildGleamPackage resolves gleam, erlang and rebar3
    # from whichever nixpkgs is here.
    dull-nix.url = "github:dull-ca/nix";
  };

  outputs = { self, nixpkgs, flake-utils, dull-nix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ dull-nix.overlays.default ];
        };

        inherit (pkgs) lib;

        # beam_minimal, not beam27Packages.erlang: the latter builds wx and drags
        # in GTK and webkit, taking the closure from 177 MB to 1,084 MB.
        # container-closure-within-budget holds the line.
        erlang = pkgs.beam_minimal.interpreters.erlang_27;

        # Keeps a stale local build/ out of the derivation's inputs.
        gleamSource = name: src: lib.cleanSourceWith {
          inherit name;
          src = lib.cleanSource src;
          filter = path: type:
            let base = baseNameOf path; in
            !(base == "build" && type == "directory") && base != ".github";
        };

        clientSrc = gleamSource "bc-client-src" ./client;
        serverSrc = gleamSource "bc-server-src" ./server;

        # client.mjs is generated below; a developer's copy must not be an input.
        clientStatic = lib.cleanSourceWith {
          name = "bc-client-static";
          src = ./client/priv/static;
          filter = path: _type: baseNameOf path != "client.mjs";
        };

        clientJs = pkgs.buildGleamPackage {
          pname = "bc-client-js";
          src = clientSrc;
          target = "javascript";
        };

        # Same script `build-client` runs in the devenv shell, so the two bundles
        # cannot drift.
        clientDist = pkgs.runCommand "bc-client-dist"
          { nativeBuildInputs = [ pkgs.esbuild pkgs.bash ]; } ''
          mkdir -p "$out"
          cp -r ${clientStatic}/. "$out/"
          bash ${./ci/build-client.sh} ${clientJs} "$out"
        '';

        serverShipment = pkgs.buildGleamPackage {
          pname = "bc-server";
          src = serverSrc;
          inherit erlang;
        };

        # Not the shipment's own entrypoint.sh: that and erl are both /bin/sh
        # scripts, and the image has no /bin/sh. This brings its own bash.
        launcher = pkgs.writeShellApplication {
          name = "bc-server";
          runtimeInputs = [ erlang ];
          text = ''
            # -pa takes one argument per ebin directory; the glob must split.
            # shellcheck disable=SC2086
            exec erl -pa ${serverShipment}/*/ebin \
              -eval 'server@@main:run(server)' \
              -noshell \
              -extra "$@"
          '';
        };

        # A real path rather than a store path, so STATIC_DIRECTORY reads sanely
        # in `docker inspect`.
        staticRoot = pkgs.runCommand "bc-static-root" { } ''
          mkdir -p "$out/var/www/bc"
          cp -r ${clientDist}/. "$out/var/www/bc/"
        '';

        container = pkgs.dockerTools.buildLayeredImage {
          name = "bc";
          tag = "latest";
          contents = [
            launcher
            staticRoot
            # /etc/passwd and /etc/group, so `nobody` resolves.
            pkgs.dockerTools.fakeNss
          ];
          # wisp needs a writable /tmp. It has to be done here -- store
          # canonicalisation would revert a chmod made any earlier.
          extraCommands = ''
            mkdir -p tmp
            chmod 1777 tmp
          '';
          config = {
            Entrypoint = [ "${launcher}/bin/bc-server" ];
            Env = [
              "STATIC_DIRECTORY=/var/www/bc"
              "PORT=8000"
              # erlang reads HOME, and `nobody` has no home here.
              "HOME=/tmp"
            ];
            ExposedPorts = { "8000/tcp" = { }; };
            User = "nobody";
            Labels = {
              "org.opencontainers.image.description" =
                "Serves plaintext HTTP only, behind a TLS-terminating reverse "
                + "proxy. Set PORT to move it off 8000 and STATIC_DIRECTORY to "
                + "serve a different tree.";
              "org.opencontainers.image.source" = "https://github.com/Byte-Club-YYC/bc";
            };
          };
        };

        release = pkgs.mkReleaseCommand {
          hooks = ./ci/release-hooks.sh;
          repositoryUrl = "https://github.com/Byte-Club-YYC/bc";
          warmCommand = "warm-cache";
          releaseWorkflow = "release.yml";
        };

        # Reuses the resolved dependency tree by replacing buildGleamPackage's
        # phases.
        gleamCheck = { name, src, target ? "erlang", nativeBuildInputs ? [ ], command }:
          pkgs.buildGleamPackage {
            pname = name;
            inherit src target nativeBuildInputs;
            buildPhase = ''
              runHook preBuild
              ${command}
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              touch "$out"
              runHook postInstall
            '';
          };
      in
      {
        # container is in checks as well as packages so warm-cache covers it and
        # CI's `nix build .#container` is a cache hit.
        checks = {
          client-test = gleamCheck {
            name = "bc-client-test";
            src = clientSrc;
            target = "javascript";
            nativeBuildInputs = [ pkgs.nodejs ];
            command = "gleam test";
          };

          server-test = gleamCheck {
            name = "bc-server-test";
            src = serverSrc;
            command = "gleam test";
          };

          client-format = gleamCheck {
            name = "bc-client-format";
            src = clientSrc;
            target = "javascript";
            command = "gleam format --check src test";
          };

          server-format = gleamCheck {
            name = "bc-server-format";
            src = serverSrc;
            command = "gleam format --check src test";
          };

          inherit container;

          # Headroom over today's 187 MB, not a measurement of it: this catches
          # the full-OTP swap (>1 GB), not an erlang point release.
          container-closure-within-budget =
            let
              runtimeClosure = pkgs.closureInfo { rootPaths = [ launcher staticRoot ]; };
              ceilingBytes = 250000000;
            in
            pkgs.runCommand "container-closure-within-budget" { } ''
              bytes=$(cut -f1 ${runtimeClosure}/total-nar-size)
              echo "container runtime closure: $bytes bytes (ceiling ${toString ceilingBytes})"

              if [ "$bytes" -gt ${toString ceilingBytes} ]; then
                echo "FAIL: runtime closure past its ceiling -- is \`erlang\` above"
                echo "still a beam_minimal build?"
                exit 1
              fi

              touch $out
            '';

          # Boots the real shipment against the real bundle -- the only check
          # covering server and client together.
          server-serves = pkgs.runCommand "bc-server-serves"
            { nativeBuildInputs = [ erlang pkgs.curl ]; } ''
            export HOME="$TMPDIR"
            export STATIC_DIRECTORY=${clientDist}
            export PORT=8099

            erl -pa ${serverShipment}/*/ebin \
              -eval 'server@@main:run(server)' -noshell &
            server=$!
            trap 'kill $server 2>/dev/null || true' EXIT

            for _ in $(seq 1 60); do
              curl -sf -o /dev/null http://127.0.0.1:8099/ && break
              sleep 0.5
            done

            root=$(curl -s -o body.html -w '%{http_code} %{content_type}' http://127.0.0.1:8099/)
            [ "$root" = "200 text/html; charset=utf-8" ] \
              || { echo "FAIL: / answered '$root'"; exit 1; }
            grep -q 'id="app"' body.html \
              || { echo "FAIL: / did not serve the index that mounts the app"; cat body.html; exit 1; }

            bundle=$(curl -s -o bundle.mjs -w '%{http_code}' http://127.0.0.1:8099/client.mjs)
            [ "$bundle" = 200 ] \
              || { echo "FAIL: /client.mjs answered $bundle"; exit 1; }
            grep -q 'Byte Club' bundle.mjs \
              || { echo "FAIL: the served bundle does not contain the app"; exit 1; }

            logo=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8099/assets/byte-club-logo.jpg)
            [ "$logo" = 200 ] || { echo "FAIL: /assets answered $logo"; exit 1; }

            ping=$(curl -s -X POST http://127.0.0.1:8099/ping)
            [ "$ping" = '{"ping":"pong"}' ] \
              || { echo "FAIL: /ping answered '$ping'"; exit 1; }

            missing=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8099/definitely-not-here)
            [ "$missing" = 404 ] || { echo "FAIL: an unknown path answered $missing"; exit 1; }

            touch "$out"
          '';

          # Held under the dull-nix revision this flake pins, not dull-nix's own.
          release-guards-hold = pkgs.releaseGuardsTest;

          # Stub skopeo: the only way to exercise the 401-vs-404 classification
          # without a network call.
          release-hooks-hold = pkgs.runCommand "release-hooks-hold" { } ''
            mkdir -p bin
            cat >bin/skopeo <<'STUB'
            #!/bin/sh
            printf '%s\n' "$SKOPEO_STDERR" >&2
            exit "$SKOPEO_STATUS"
            STUB
            chmod +x bin/skopeo
            export PATH=$PWD/bin:${pkgs.releaseGuards}/bin:$PATH

            hooks=${release}/bin/release-hooks

            $hooks assert-ready \
              || { echo "assert-ready must pass with skopeo and release-guards on PATH"; exit 1; }

            SKOPEO_STATUS=1 SKOPEO_STDERR='manifest unknown' \
              $hooks assert-unpublished v1.2.3 \
              || { echo "a missing manifest must read as unpublished"; exit 1; }

            SKOPEO_STATUS=1 SKOPEO_STDERR='name unknown' \
              $hooks assert-unpublished v1.2.3 \
              || { echo "a missing repository must read as unpublished"; exit 1; }

            if SKOPEO_STATUS=1 SKOPEO_STDERR='unauthorized: authentication required' \
              $hooks assert-unpublished v1.2.3 2>/dev/null; then
              echo "a 401 must refuse, not pass as unpublished"; exit 1
            fi

            if SKOPEO_STATUS=0 SKOPEO_STDERR=none \
              $hooks assert-unpublished v1.2.3 2>/dev/null; then
              echo "an existing tag must refuse"; exit 1
            fi

            described=$($hooks describe v1.2.3)
            printf '%s\n' "$described" | grep -Fqx 'image     ghcr.io/byte-club-yyc/bc:1.2.3' \
              || { echo "describe must name the image and tag a release publishes"; exit 1; }
            printf '%s\n' "$described" | grep -Fqx ':latest   moves to v1.2.3' \
              || { echo "describe must say :latest moves for a stable version"; exit 1; }

            prereleased=$($hooks describe v1.2.3-rc1)
            printf '%s\n' "$prereleased" | grep -Fqx ':latest   unchanged -- v1.2.3-rc1 is a prerelease' \
              || { echo "describe must leave :latest where it is for a prerelease"; exit 1; }

            [ "$($hooks set-version v1.2.3 2>&1 | wc -c)" -eq 0 ] \
              || { echo "set-version must write nothing -- the release commit carries CHANGELOG.md alone"; exit 1; }

            # release.yml reads the image name from here rather than repeating it.
            [ "$($hooks image)" = 'ghcr.io/byte-club-yyc/bc' ] \
              || { echo "the image subcommand must name the published image"; exit 1; }

            usage_status=0
            $hooks not-a-hook >/dev/null 2>&1 || usage_status=$?
            [ "$usage_status" -eq 2 ] \
              || { echo "an unknown hook must exit 2, not $usage_status"; exit 1; }

            touch $out
          '';
        };

        packages = {
          inherit container release;
          client = clientDist;
          server = serverShipment;
          # For a CI job re-checking a hand-pushed tag.
          release-guards = pkgs.releaseGuards;
        };
      });
}
