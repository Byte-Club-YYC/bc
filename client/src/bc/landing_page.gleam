import lustre
import lustre/attribute.{class, src}
import lustre/element.{text}
import lustre/element/html.{a, div, h1, img, li, nav, ul}
import sketch

const filler = "Welcome to the ultimate hackathon experience! Join us for a weekend of innovation, collaboration, and creativity as we bring together the brightest minds in technology. Whether you're a seasoned coder or a first-time hacker, our hackathon offers a platform for you to showcase your skills, learn from industry experts, and build something amazing. Get ready to hack your way to success and unleash your potential. Don't miss out on this opportunity to network, compete, and make a difference. Register now and let the hacking begin ..."

pub fn app() {
  lustre.simple(init, update, view)
}

pub fn init(_) {
  0
}

pub fn update(model, _msg) {
  model
}

fn nav_list() {
  [
    sketch.display("flex"),
    sketch.flex_direction("row"),
    sketch.align_items("center"),
    sketch.list_style_type("none"),
    sketch.padding_("0"),
    sketch.margin_("0"),
    sketch.display("inline"),
  ]
  |> sketch.class()
  |> sketch.to_lustre()
}

fn nav_list_li() {
  [
    sketch.padding_("10px 20px"),
    sketch.list_style_type("none"),
    sketch.display("inline"),
  ]
  |> sketch.class()
  |> sketch.to_lustre()
}

fn nav_list_link() {
  [
    sketch.text_decoration("none"),
    sketch.hover([sketch.background("rgba(var(--ctp-mocha-base-rgb), 0.8)")]),
  ]
  |> sketch.class()
  |> sketch.to_lustre()
}

fn container() {
  [
    sketch.display("flex"),
    sketch.flex_direction("column"),
    sketch.align_items("center"),
    sketch.border("1px solid black"),
  ]
  |> sketch.class()
  |> sketch.to_lustre()
}

fn content() {
  [
    sketch.display("flex"),
    sketch.flex_direction("row"),
    sketch.justify_content("center"),
  ]
  |> sketch.class()
  |> sketch.to_lustre()
}

fn row_item() {
  [sketch.max_width_("50rem"), sketch.justify_content("center")]
  |> sketch.class()
  |> sketch.to_lustre()
}

fn top_bar() {
  nav([], [
    ul([nav_list()], [
      li([nav_list_li()], [
        a([], [
          img([
            src("assets/byte-club-logo.jpg"),
            class("bc-round-img bc-tiny-img"),
          ]),
        ]),
      ]),
      li([nav_list_li()], [a([nav_list_link()], [text("About")])]),
      li([nav_list_li()], [a([nav_list_link()], [text("Contact")])]),
      li([nav_list_li()], [a([nav_list_link()], [text("Showcase")])]),
    ]),
  ])
}

pub fn view(_model) {
  div([], [
    top_bar(),
    div([container()], [
      h1([], [text("Byte Club")]),
      img([src("assets/byte-club-logo.jpg"), class("bc-round-img bc-big-img")]),
      div([content()], [div([row_item()], [text(filler)])]),
    ]),
  ])
}
