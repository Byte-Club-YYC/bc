import gleam/option.{None, Some}
import gleam/uri

@external(javascript, "./ffi.mjs", "initial_uri")
pub fn initial_uri() -> uri.Uri {
  uri.Uri(None, None, None, None, "", None, None)
}

pub fn server_url() -> String {
  let init = initial_uri()
  let scheme = case init.scheme {
    Some(v) -> v
    None -> "https:"
  }
  let host = case init.host {
    Some(v) -> v
    None -> "byteclub.yyc.dev"
  }
  scheme <> "//" <> host
}
