import bc/web
import gleam/string_builder
import lustre/element.{to_string}
import wisp.{type Request, type Response}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request) -> Response {
  // Apply the middleware stack for this request/response.
  use _req <- web.middleware(req)

  let body = string_builder.from_string("Whoops! There's no frontend right now")

  // Return a 200 OK response with the body and a HTML content type.
  wisp.html_response(body, 200)
}
