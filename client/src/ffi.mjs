import { Ok, Error } from "./gleam.mjs";
import { Some, None } from "../gleam_stdlib/gleam/option.mjs";
import { Uri } from "../gleam_stdlib/gleam/uri.mjs";

// On first call rather than at module load, so the module stays importable
// without a `window` -- which is what `gleam test` under node is.
let initial_location = undefined;

export const initial_uri = () => {
  if (initial_location === undefined) {
    initial_location = window.location.href;
  }
  return uri_from_url(new URL(initial_location));
};

const uri_from_url = (url) => {
  return new Uri(
    /* scheme   */ new (url.protocol ? Some : None)(url.protocol),
    /* userinfo */ new None(),
    /* host     */ new (url.host ? Some : None)(url.host),
    /* port     */ new (url.port ? Some : None)(url.port),
    /* path     */ url.pathname,
    /* query    */ new (url.search ? Some : None)(url.search),
    /* fragment */ new (url.hash ? Some : None)(url.hash.slice(1)),
  );
};
