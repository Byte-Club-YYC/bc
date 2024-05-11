import bc/web
import gleam/http
import gleam/io.{debug}
import gleam/json
import wisp.{type Request, type Response, File, response, set_body}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  // Apply the middleware stack for this request/response.
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> home_page(req, ctx)
    ["ping"] -> pong(req)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, http.Get)
  // Default to the index.html if nothing else is here.
  response(200)
  |> set_body(File(debug(ctx.static_directory <> "/index.html")))
}

fn pong(req: Request) -> Response {
  use <- wisp.require_method(req, http.Post)
  json.object([#("ping", json.string("pong"))])
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
