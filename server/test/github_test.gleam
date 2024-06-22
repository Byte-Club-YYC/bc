import bc/github.{Credentials, credentials_from_env}
import birdie
import dot_env/env
import gleeunit/should
import pprint

pub fn both_empty_github_credentials_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "")
  |> should.be_ok()

  credentials_from_env()
  |> should.be_error()
  |> pprint.format
  |> birdie.snap(title: "both_empty_github_credentials_test")
}

pub fn client_id_empty_github_credentials_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "Heeyo")
  |> should.be_ok()

  credentials_from_env()
  |> should.be_error()
  |> pprint.format
  |> birdie.snap(title: "client_id_empty_github_credentials_test")
}

pub fn client_secret_empty_github_credentials_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "Heeyo")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "")
  |> should.be_ok()

  credentials_from_env()
  |> should.be_error()
  |> pprint.format
  |> birdie.snap(title: "client_secret_empty_github_credentials_test")
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
