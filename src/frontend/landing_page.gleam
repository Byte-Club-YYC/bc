import lustre
import lustre/element.{text}
import lustre/element/html.{div, h1, img, li, nav, ul}
import lustre/attribute.{class, src}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

const filler = "Welcome to the ultimate hackathon experience! Join us for a weekend of innovation, collaboration, and creativity as we bring together the brightest minds in technology. Whether you're a seasoned coder or a first-time hacker, our hackathon offers a platform for you to showcase your skills, learn from industry experts, and build something amazing. Get ready to hack your way to success and unleash your potential. Don't miss out on this opportunity to network, compete, and make a difference. Register now and let the hacking begin!"

fn init(_) {
  0
}

fn update(model, _msg) {
  model
}

fn view(_model) {
  landing_page()
}

fn landing_page() {
  div([], [
    nav([], [
      ul([], [
        li([], [text("About")]),
        li([], [text("Contact")]),
        li([], [text("Showcase")]),
      ]),
    ]),
    div([class("container")], [
      h1([], [text("Byte Club")]),
      img([
        src(
          "https://static.vecteezy.com/system/resources/thumbnails/002/412/377/small/coffee-cup-logo-coffee-shop-icon-design-free-vector.jpg",
        ),
      ]),
      div([class("content")], [div([class("row-item")], [text(filler)])]),
    ]),
  ])
}
