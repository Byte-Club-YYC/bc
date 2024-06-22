import bc/fp/env
import gleam/option.{type Option}

import valid as v
import valid/common.{type ValidatorResult}
import valid/option as v_opt
import valid/string as v_string

pub type CredentialsInput {
  CredentialsInput(client_secret: Option(String), client_id: Option(String))
}

pub type Credentials {
  Credentials(client_secret: String, client_id: String)
}

fn some_and_not_empty_validator(name: String) {
  v_opt.is_some(name <> " is required")
  |> v.and(v_string.min_length(name <> " must not be empty", 1))
}

pub fn credentials_validator(
  credentials_input: CredentialsInput,
) -> ValidatorResult(Credentials, String) {
  v.build2(Credentials)
  |> v.validate(
    credentials_input.client_secret,
    some_and_not_empty_validator("BC_GITHUB_OAUTH_CLIENT_SECRET"),
  )
  |> v.validate(
    credentials_input.client_id,
    some_and_not_empty_validator("BC_GITHUB_OAUTH_CLIENT_ID"),
  )
}

pub fn credentials_input_from_env() {
  CredentialsInput(
    client_secret: env.get_string_optional("BC_GITHUB_OAUTH_CLIENT_SECRET"),
    client_id: env.get_string_optional("BC_GITHUB_OAUTH_CLIENT_ID"),
  )
}

pub fn credentials_from_env() {
  credentials_validator(credentials_input_from_env())
}

fn base_url() {
  "https://github.com/"
}

fn oauth_login_base_url() {
  base_url() <> "login/oauth/authorize"
}

pub type LoginRequest {
  LoginRequest(
    credentials: Credentials,
    redirect_uri: String,
    scope: Option(String),
    state: Option(String),
  )
}

pub fn oauth_token_url() {
  oauth_login_base_url() <> "login/oauth/access_token"
}
