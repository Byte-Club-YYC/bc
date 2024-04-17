import gleam/list
import lustre
import lustre/attribute.{class, src}
import lustre/element.{text}
import lustre/element/html.{a, div, h1, img, li, nav, p, ul}
import sketch
import sketch/options as sketch_options

pub fn app() {
  let assert Ok(render) =
    sketch_options.node()
    |> sketch.lustre_setup()
  lustre.simple(init, update, render(view))
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

fn tldr() {
  div([], [
    h1([], [text("TL;DR")]),
    text("The premise is simple"),
    ul([], [
      li([], [text("Go to a coffee shop or collaboration space")]),
      li([], [text("Work on whatever project you've been wanting to work on")]),
      li([], [text("Ask for help from others when you need it")]),
      li([], [text("Give help to those who ask for it")]),
    ]),
    text(
      "All skill levels and interests are welcome. It doesn't matter if you're an absolute beginner or a seasoned developer.",
    ),
  ])
}

fn wmro() {
  [
    h1([], [text("WM;RO (want more? read on)")]),
    p([], [
      text(
        "
The whole goal of this little group is to have a space and time to make progress on your
coding side projects. This stems from the idea of body doubling where the social pressure
of having others around you doing work will motivate you to also work. Folks with ADHD
especially benefit from this type of work. (look up \"body doubling\" in the context of
ADHD and productivity for more info)",
      ),
    ]),
    p([], [
      text(
        "
It won't only be heads down and working. We're leaving room for socializing, helping each
other out and learning new things. One of the best ways to learn is to have an experienced
person sit next to you while you work through problems and point out all the gotchas, mistakes,
intricacies and conventions about whatever you're working on. This helps with that.",
      ),
    ]),
    p([], [
      text(
        "
So what do you need to know before coming? Nothing. All you need is a computer, an idea
of what you'd like to work on or learn, and some curiosity.",
      ),
    ]),
  ]
}

pub fn view(_model) {
  let container_style =
    [
      sketch.display("flex"),
      sketch.flex_direction("column"),
      sketch.align_items("center"),
      sketch.justify_content("center"),
      sketch.max_width_("50rem"),
    ]
    |> sketch.class()
    |> sketch.to_lustre()

  div([], [
    top_bar(),
    div(
      [container_style],
      list.concat([
        [
          h1([], [text("Byte Club")]),
          img([
            src("assets/byte-club-logo.jpg"),
            class("bc-round-img bc-big-img"),
          ]),
          tldr(),
        ],
        wmro(),
      ]),
    ),
  ])
}
