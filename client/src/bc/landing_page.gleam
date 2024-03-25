import lustre
import lustre/element.{text}
import lustre/element/html.{a, div, h1, img, li, nav, ul}
import lustre/attribute.{class, src}

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

pub fn view(_model) {
  div([], [
    nav([], [
      ul([], [
        li([], [a([], [text("About")])]),
        li([], [a([], [text("Contact")])]),
        li([], [a([], [text("Showcase")])]),
      ]),
    ]),
    div([class("container")], [
      h1([], [text("Byte Club")]),
      img([
        src(
          "https://static.vecteezy.com/system/resources/thumbnails/002/412/377/small/coffee-cup-logo-coffee-shop-icon-design-free-vector.jpg",
        ),
        class("round_img"),
      ]),
      div([class("content")], [div([class("row-item")], [text(filler)])]),
    ]),
  ])
}
