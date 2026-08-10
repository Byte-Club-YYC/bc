# Byte Club Website

Website and home of the Byte Club. Let's get creative and make a welcoming place
where we can work together on our projects.

## Top Level Premise

We want the idea of hosts and guests for a self organizing grassroots style club.
- Hosts are the folks that name a time and place where they'll be working on a project
- Guests are the folks who sign up and join the host

We'd really like a high turnout percentage so that hosts can reliably know how many
folks are showing up. At some point, we'd like to have some system that can keep
track of that to keep folks honest.

## Other Ideas

This website could go anywhere. Here are some ideas
- A feed where folks can post their project demos
- Integration with Google Maps to post where the host is going
- Integration with the Zulip channel to notify of host locations
- Friends of byte club page to point folks to other programming clubs in Calgary
- Projects/languages/technologies heat map by user to get folks with similar
  interests in contact with each other

Any idea is welcome though. It's our website. We can make whatever we want!

# Development

The website uses the following tech stack
- [gleam lang](https://gleam.run/)
- [lustre frontend](https://github.com/lustre-labs/lustre)
- [wisp backend](https://github.com/gleam-wisp/wisp)

The project has two packages, and they are independent — the server does not
depend on the client, and each resolves its own dependency versions. That is
deliberate: `lustre_ui` holds the frontend to `lustre` 4 and `gleam_stdlib`
0.47, and coupling the two would hold the server there too, off `wisp` 2.x and
its `serve_static` security fix. Each `gleam.toml` explains its own ceilings.

- [client](./client) is the frontend, compiled to JavaScript and bundled into
  one `client.mjs`
- [server](./server) serves that bundle, and the API, on port 8000

## Getting set up

Everything comes from [devenv](https://devenv.sh) — gleam, erlang, rebar3,
esbuild, node. Nothing needs to be installed by hand.

```sh
direnv allow    # activate the shell automatically
devenv shell    # or enter it manually
```

| Command          | What it does                                              |
| :--------------- | :-------------------------------------------------------- |
| `devenv up`      | build the client, serve it, and rebuild it on every change |
| `build-client`   | compile the frontend and bundle it to `client/priv/static` |
| `run-server`     | run the server on <http://localhost:8000>                  |
| `run-tests`      | `gleam test` in both packages                              |
| `format`         | `gleam format` in both packages                            |
| `gate`           | the full `nix flake check` — what CI runs                  |
| `release`        | cut a release; see below                                   |

`run-server` on its own serves whatever `build-client` last wrote, so run that
first (or use `devenv up`, which does both).

## The build

`nix` owns the whole build — no gleam or erlang is installed on a CI runner, and
a build of a given commit produces the same image every time.

```sh
nix flake check        # both test suites, both format checks, the bundle,
                       # the image, the server actually serving, the release
                       # guards and hooks
nix build .#client     # the bundled frontend
nix build .#server     # the erlang shipment
nix build .#container  # the docker archive
```

Dependencies come from `manifest.toml` with no hash to maintain — gleam records
a checksum for every package, and that checksum is what nix verifies the
download against. Adding a dependency is `gleam add`, and nothing else.

The client is bundled with esbuild rather than `lustre/dev build`, because that
downloads an esbuild binary mid-build and a nix sandbox has no network.
`ci/build-client.sh` is the one definition of that step, run by both the nix
build and `build-client`.

## Container image

`nix build .#container` writes a docker archive that runs the server as
`nobody` on port 8000, serving the client from `/var/www/bc`. Both are
configurable at runtime:

```sh
docker load < result
docker run -p 8080:8000 bc:latest
docker run -p 8080:9000 -e PORT=9000 bc:latest
```

It serves plaintext HTTP and belongs behind a TLS-terminating reverse proxy.

## Releasing

`release`, in the devenv shell. The bare form reads the version from the
conventional-commit subjects since the latest stable tag; `release
major|minor|patch|vX.Y.Z` names it instead. It shows every merge it read and the
changelog it will write, waits for a literal `Y`, then commits `CHANGELOG.md`,
warms the cache, pushes `main`, tags that commit, and watches the `release.yml`
run that publishes `ghcr.io/byte-club-yyc/bc`.

Have ready: a clean `main` that is not behind `origin/main`, an authenticated
`gh`, and a cachix write token for the `dull-ca` cache (`cachix authtoken`, or
`CACHIX_AUTH_TOKEN`) — `warm-cache` runs after the confirmation, and a missing
token stops it there. The publish guard asks ghcr.io whether the version already
exists and refuses on any answer it cannot read as absence, so `skopeo login
ghcr.io` may be needed as well.

The process itself lives in [`dull-ca/nix`](https://github.com/dull-ca/nix), so
that the repositories sharing it share one set of guards rather than four
copies that drift. See that repository's README, under `mkReleaseCommand`.
