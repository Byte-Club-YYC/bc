import bc/config.{Config}
import bc/github.{Credentials}
import birdie
import dot_env/env
import gleamsver
import gleeunit/should
import pprint

pub fn empty_version_config_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "Heeyo ID")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "Heeyo SECRET")
  |> should.be_ok()
  env.set("BC_VERSION", "")
  |> should.be_ok()

  config.from_env()
  |> should.be_error()
  |> pprint.format
  |> birdie.snap(title: "empty_version_config_test")
}

pub fn bad_version_config_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "Heeyo ID")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "Heeyo SECRET")
  |> should.be_ok()
  env.set("BC_VERSION", "ytujhgh")
  |> should.be_ok()

  config.from_env()
  |> should.be_error()
  |> pprint.format
  |> birdie.snap(title: "bad_version_config_test")
}

pub fn good_version_config_test() {
  env.set("BC_GITHUB_OAUTH_CLIENT_ID", "Heeyo ID")
  |> should.be_ok()
  env.set("BC_GITHUB_OAUTH_CLIENT_SECRET", "Heeyo SECRET")
  |> should.be_ok()
  env.set("BC_VERSION", "0.1.2")
  |> should.be_ok()

  config.from_env()
  |> should.be_ok()
  |> should.equal(Config(
    Credentials("Heeyo SECRET", "Heeyo ID"),
    gleamsver.SemVer(0, 1, 2, "", ""),
  ))
}
