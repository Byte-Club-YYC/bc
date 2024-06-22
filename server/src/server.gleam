import bc/config
import bc/router
import bc/web.{Context}
import dot_env as dot
import gleam/erlang/process
import gleam/io.{debug}
import mist
import wisp

pub fn main() {
  dot.new()
  |> dot.set_path(".env")
  |> dot.set_debug(True)
  |> dot.load

  let assert Ok(config) = config.from_env()

  // This sets the logger to print INFO level logs, and other sensible defaults
  // for a web application.
  wisp.configure_logger()

  // Here we generate a secret key, but in a real application you would want to
  // load this from somewhere so that it is not regenerated on every restart.
  let secret_key_base = wisp.random_string(64)

  // A context is constructed holding the static directory path.
  let ctx = Context(static_directory: static_directory(), config: config)

  let handler = router.handle_request(_, ctx)

  // Start the Mist web server.
  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  process.sleep_forever()

  Ok(Nil)
}

pub fn static_directory() -> String {
  // The priv directory is where we store non-Gleam and non-Erlang files,
  // including static assets to be served.
  // This function returns an absolute path and works both in development and in
  // production after compilation.
  let assert Ok(priv_directory) = wisp.priv_directory("client")
  debug(priv_directory <> "/static")
}
