pub type Error {
  BadConfig(msg: String)
  MissingEnvironmentVariable(msg: String)
}
