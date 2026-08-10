import bc/landing_page
import gleam/option.{None}
import gleam/string
import gleeunit
import lustre/element

pub fn main() {
  gleeunit.main()
}

pub fn init_starts_without_a_ping_test() {
  let #(model, _effect) = landing_page.init(Nil)

  assert model.ping == None
}

pub fn view_renders_the_club_name_test() {
  let #(model, _effect) = landing_page.init(Nil)
  let html = element.to_string(landing_page.view(model))

  assert string.contains(html, "Byte Club")
}

pub fn view_prompts_for_a_ping_before_one_arrives_test() {
  let #(model, _effect) = landing_page.init(Nil)
  let html = element.to_string(landing_page.view(model))

  assert string.contains(html, "Press the button to ping the server")
}
