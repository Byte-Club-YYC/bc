import gleam/result

pub fn zip(r1: Result(a, c), r2: Result(b, c)) -> Result(#(a, b), c) {
  result.then(r1, fn(v1) { result.map(r2, fn(v2) { #(v1, v2) }) })
}
