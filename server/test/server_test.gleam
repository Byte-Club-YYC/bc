import bc/router
import bc/web.{type Context, Context}
import gleam/http
import gleam/http/response as http_response
import gleeunit
import wisp/simulate

pub fn main() {
  gleeunit.main()
}

fn context() -> Context {
  Context(static_directory: "test/fixtures")
}

fn handle(request) {
  router.handle_request(request, context())
}

pub fn home_page_serves_the_index_test() {
  let response = simulate.request(http.Get, "/") |> handle

  assert response.status == 200
  assert simulate.read_body(response) == "<!doctype html>\n"
}

pub fn home_page_is_html_test() {
  let response = simulate.request(http.Get, "/") |> handle

  assert http_response.get_header(response, "content-type")
    == Ok("text/html; charset=utf-8")
}

pub fn ping_answers_pong_test() {
  let response = simulate.request(http.Post, "/ping") |> handle

  assert response.status == 200
  assert simulate.read_body(response) == "{\"ping\":\"pong\"}"
}

pub fn ping_refuses_get_test() {
  let response = simulate.request(http.Get, "/ping") |> handle

  assert response.status == 405
}

pub fn unknown_path_is_not_found_test() {
  let response = simulate.request(http.Get, "/definitely-not-here") |> handle

  assert response.status == 404
}

/// wisp 2.1.1 and 2.2.0 were retired over exactly this.
pub fn static_paths_cannot_escape_the_directory_test() {
  let response = simulate.request(http.Get, "/../gleam.toml") |> handle

  assert response.status != 200
}
