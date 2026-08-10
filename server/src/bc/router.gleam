import bc/web
import gleam/http
import gleam/json
import gleam/option.{None}
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
  // serve_static never matches `/`, so the index and its content type are
  // sent from here.
  response(200)
  |> wisp.set_header("content-type", "text/html; charset=utf-8")
  |> set_body(File(
    path: ctx.static_directory <> "/index.html",
    offset: 0,
    limit: None,
  ))
}

fn pong(req: Request) -> Response {
  use <- wisp.require_method(req, http.Post)
  json.object([#("ping", json.string("pong"))])
  |> json.to_string
  |> wisp.json_response(200)
}
