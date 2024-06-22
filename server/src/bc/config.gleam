import bc/fp/env
import bc/github.{credentials_from_env}
import gleam/option.{type Option, None, Some}
import gleamsver
import valid as v
import valid/option as v_opt
import valid/string as v_string

pub type Config {
  Config(github_credentials: github.Credentials, version: gleamsver.SemVer)
}

fn parse_version(version: String) -> Option(gleamsver.SemVer) {
  case gleamsver.parse_loosely(version) {
    Ok(v) -> Some(v)
    Error(_) -> None
  }
}

pub fn from_env() {
  let name = "BC_VERSION"
  v.build2(Config)
  |> v.validate(Nil, fn(_) { credentials_from_env() })
  |> v.validate(
    env.get_string_optional(name),
    v_opt.is_some(name <> " must not be empty")
      |> v.and(v_string.min_length(name <> " must not be empty", 1))
      |> v.and(v.custom(name <> " must be a valid semver", parse_version)),
  )
}
