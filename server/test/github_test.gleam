import bc/github.{Credentials, credentials_from_env}
import dot_env/env
import gleeunit/should

pub fn both_empty_github_credentials_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "")
  |> should.be_ok()

  credentials_from_env()
  |> should.be_error()
  |> should.equal(
    #("BC_GITHUB_OAUTH_CLIENT_SECRET must not be empty", [
      "BC_GITHUB_OAUTH_CLIENT_SECRET must not be empty",
      "BC_GITHUB_OAUTH_CLIENT_ID must not be empty",
    ]),
  )
}

pub fn client_id_empty_github_credentials_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "Heeyo")
  |> should.be_ok()

  credentials_from_env()
  |> should.be_error()
  |> should.equal(
    #("BC_GITHUB_OAUTH_CLIENT_ID must not be empty", [
      "BC_GITHUB_OAUTH_CLIENT_ID must not be empty",
    ]),
  )
}

pub fn client_secret_empty_github_credentials_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "Heeyo")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "")
  |> should.be_ok()

  credentials_from_env()
  |> should.be_error()
  |> should.equal(
    #("BC_GITHUB_OAUTH_CLIENT_SECRET must not be empty", [
      "BC_GITHUB_OAUTH_CLIENT_SECRET must not be empty",
    ]),
  )
}

pub fn both_set_github_credentials_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "Heeyo ID")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "Heeyo Secret")
  |> should.be_ok()

  credentials_from_env()
  |> should.be_ok()
  |> should.equal(Credentials("Heeyo Secret", "Heeyo ID"))
}
