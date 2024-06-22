import bc/error
import dot_env/env
import gleam/option.{None, Some}
import gleam/result

pub fn get_string_required(name: String) {
  env.get(name)
  |> result.replace_error(error.MissingEnvironmentVariable(
    name <> " is required",
  ))
}

pub fn get_string_optional(name: String) {
  case env.get(name) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}
