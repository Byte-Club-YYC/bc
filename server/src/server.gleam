import bc/router
import bc/web.{type GithubSettings, Context, GithubSettings}
import gleam/erlang/process
import gleam/io.{debug}
import mist
import wisp

import gleam/result.{map_error, replace_error, try}
import glenvy/dotenv
import glenvy/env

pub fn github_settings() -> Result(GithubSettings, String) {
  use _ <- try(map_error(dotenv.load(), fn(_) { "Unable to load .env file" }))
  use github_secret <- try(replace_error(
    env.get_string("GITHUB_OAUTH_CLIENT_SECRET"),
    "Unable to load GITHUB_OAUTH_CLIENT_SECRET from environment variables",
  ))
  use github_client_id <- try(replace_error(
    env.get_string("GITHUB_OAUTH_CLIENT_ID"),
    "Unable to load GITHUB_OAUTH_CLIENT_ID from environment variables",
  ))

  Ok(GithubSettings(client_id: github_client_id, client_secret: github_secret))
}

pub fn main() {
  let _ = dotenv.load()
  let github_settings = case github_settings() {
    Ok(settings) -> settings
    Error(e) -> {
      io.println("Unable to load github oauth settings: " <> e)
      panic("Unable to load github oauth settings: " <> e)
    }
  }

  // This sets the logger to print INFO level logs, and other sensible defaults
  // for a web application.
  wisp.configure_logger()

  // Here we generate a secret key, but in a real application you would want to
  // load this from somewhere so that it is not regenerated on every restart.
  let secret_key_base = wisp.random_string(64)

  // A context is constructed holding the static directory path.
  let ctx =
    Context(static_directory: static_directory(), github: github_settings)

  let handler = router.handle_request(_, ctx)

  // Start the Mist web server.
  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  Ok(process.sleep_forever())
}

pub fn static_directory() -> String {
  // The priv directory is where we store non-Gleam and non-Erlang files,
  // including static assets to be served.
  // This function returns an absolute path and works both in development and in
  // production after compilation.
  let assert Ok(priv_directory) = wisp.priv_directory("client")
  debug(priv_directory <> "/static")
}
