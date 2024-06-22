import birl
import gleam/dynamic
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute as attr
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui.{type Theme, Px, Rem, Size, Theme}
import lustre/ui/layout/cluster
import lustre/ui/prose
import lustre/ui/util/colour
import lustre/ui/util/styles
import lustre_http.{type HttpError}
import url

// Model
pub type Model {
  Model(theme: Theme, ping: Option(Ping), event: Event)
}

pub type Ping {
  Ping(ping: String)
}

pub type Event {
  Event(location: String, date: birl.Time)
}

pub fn init(_) -> #(Model, Effect(Msg)) {
  let theme =
    Theme(
      space: Size(base: Rem(1.5), ratio: 1.618),
      text: Size(base: Rem(1.125), ratio: 1.215),
      radius: Px(4.0),
      primary: colour.iris(),
      greyscale: colour.slate(),
      error: colour.red(),
      success: colour.green(),
      warning: colour.yellow(),
      info: colour.blue(),
    )
  #(
    Model(
      theme: theme,
      ping: None,
      event: Event(location: "", date: birl.now()),
    ),
    effect.none(),
  )
}

// Update

pub opaque type Msg {
  UserClickedPing
  ApiUpdatedPing(Result(Ping, HttpError))
  UserUpdatedEventLocation(value: String)
  UserUpdatedEventDate(value: String)
  UserClickedEventSubmit
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedPing -> #(model, ping())
    ApiUpdatedPing(Ok(ping)) -> #(
      Model(..model, ping: Some(ping)),
      effect.none(),
    )
    ApiUpdatedPing(Error(_)) -> #(model, effect.none())
    UserUpdatedEventLocation(value) -> #(
      Model(..model, event: Event(..model.event, location: value)),
      effect.none(),
    )
    UserUpdatedEventDate(value) ->
      case birl.parse(value) {
        Ok(date) -> #(
          Model(..model, event: Event(..model.event, date: date)),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }
    UserClickedEventSubmit -> #(model, submit_event(model))
  }
}

fn submit_event(model: Model) -> Effect(Msg) {
  io.print("woo!")
  io.print(model.event.location)
  io.print(birl.to_date_string(model.event.date))
  effect.none()
}

fn ping() -> Effect(Msg) {
  let url = url.server_url() <> "/ping"
  let decoder = dynamic.decode1(Ping, dynamic.field("ping", dynamic.string))

  lustre_http.post(
    url,
    json.object([]),
    lustre_http.expect_json(decoder, ApiUpdatedPing),
  )
}

fn tldr() {
  ui.prose([prose.full()], [
    html.h1([], [html.text("TL;DR")]),
    html.text("The premise is simple"),
    html.ul([], [
      html.li([], [html.text("Go to a coffee shop or collaboration space")]),
      html.li([], [
        html.text("Work on whatever project you've been wanting to work on"),
      ]),
      html.li([], [html.text("Ask for help from others when you need it")]),
      html.li([], [html.text("Give help to those who ask for it")]),
    ]),
    html.text(
      "All skill levels and interests are welcome. It doesn't matter if you're an absolute beginner or a seasoned developer.",
    ),
  ])
}

fn wmro() {
  ui.prose([prose.full()], [
    html.h1([], [html.text("WM;RO (want more? read on)")]),
    html.p([], [
      html.text(
        "
The whole goal of this little group is to have a space and time to make progress on your
coding side projects. This stems from the idea of body doubling where the social pressure
of having others around you doing work will motivate you to also work. Folks with ADHD
especially benefit from this type of work. (look up \"body doubling\" in the context of
ADHD and productivity for more info)",
      ),
    ]),
    html.p([], [
      html.text(
        "
It won't only be heads down and working. We're leaving room for socializing, helping each
other out and learning new things. One of the best ways to learn is to have an experienced
person sit next to you while you work through problems and point out all the gotchas, mistakes,
intricacies and conventions about whatever you're working on. This helps with that.",
      ),
    ]),
    html.p([], [
      html.text(
        "
So what do you need to know before coming? Nothing. All you need is a computer, an idea
of what you'd like to work on or learn, and some curiosity.",
      ),
    ]),
  ])
}

fn event_submission(model: Model) -> Element(Msg) {
  ui.box([], [
    ui.input([
      attr.value(model.event.location),
      event.on_input(UserUpdatedEventLocation),
    ]),
    ui.input([
      attr.type_("date"),
      attr.value(birl.to_naive_date_string(model.event.date)),
      event.on_input(UserUpdatedEventDate),
    ]),
    ui.button([event.on_click(UserClickedEventSubmit)], [html.text("Submit")]),
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  let ping_content_div = case model.ping {
    Some(val) -> html.div([], [html.text(val.ping)])
    None -> html.text("Press the button to ping the server")
  }

  let styles = [#("width", "80ch"), #("margin", "0 auto"), #("padding", "2rem")]

  html.div([], [
    styles.elements(),
    styles.scoped(model.theme, "#container"),
    ui.stack([attr.id("container"), attr.style(styles)], [
      ui.cluster([cluster.stretch()], [
        ui.prose([], [html.h1([], [html.text("Byte Club")])]),
        html.img([
          attr.src("assets/byte-club-logo.jpg"),
          attr.class("bc-round-img bc-big-img"),
        ]),
      ]),
      tldr(),
      wmro(),
      ping_content_div,
      ui.button([event.on_click(UserClickedPing)], [html.text("Ping Server")]),
      event_submission(model),
    ]),
  ])
}

// App

pub fn app() {
  lustre.application(init, update, view)
}
