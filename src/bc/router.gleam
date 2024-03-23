import wisp.{type Request, type Response}
import gleam/string_builder
import bc/web
import frontend
import lustre/element.{to_string}

/// The HTTP request handler- your application!
///
pub fn handle_request(req: Request) -> Response {
  // Apply the middleware stack for this request/response.
  use _req <- web.middleware(req)

  // Later we'll use templates, but for now a string will do.
  let body = string_builder.from_string(to_string(frontend.landing_page()))

  // Return a 200 OK response with the body and a HTML content type.
  wisp.html_response(body, 200)
}
