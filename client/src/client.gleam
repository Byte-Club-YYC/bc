import bc/landing_page
import lustre

pub fn main() {
  let app = landing_page.app()
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
