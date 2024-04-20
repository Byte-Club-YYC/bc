import bc/web
import gleam/io.{debug}
import wisp.{type Request, type Response, File, response, set_body}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  // Apply the middleware stack for this request/response.
  use _req <- web.middleware(req, ctx)

  // Default to the index.html if nothing else is here.
  response(200)
  |> set_body(File(debug(ctx.static_directory <> "/index.html")))
}
