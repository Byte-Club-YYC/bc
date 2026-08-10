import bc/router
import bc/web.{Context}
import envoy
import gleam/erlang/process
import gleam/int
import mist
import wisp
import wisp/wisp_mist

const default_port = 8000

const default_static_directory = "priv/static"

pub fn main() {
  wisp.configure_logger()

  // Regenerated per restart, invalidating every signed cookie from the last
  // run. Nothing here signs anything that has to outlive a restart yet.
  let secret_key_base = wisp.random_string(64)

  let ctx = Context(static_directory: static_directory())
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(port())
    // Loopback would be unreachable from outside the container.
    |> mist.bind("0.0.0.0")
    |> mist.start

  process.sleep_forever()
}

fn static_directory() -> String {
  case envoy.get("STATIC_DIRECTORY") {
    Ok(directory) -> directory
    Error(_) -> default_static_directory
  }
}

/// Crashes on an unreadable PORT rather than falling back -- listening
/// somewhere other than where it was told is worse than refusing to start.
fn port() -> Int {
  case envoy.get("PORT") {
    Error(_) -> default_port
    Ok(value) -> {
      let assert Ok(port) = int.parse(value)
      port
    }
  }
}
