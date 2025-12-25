import gleam/regexp

@internal
pub opaque type Constant {
  Constant(value: String)
}

@internal
pub fn new(value: String) -> Result(Constant, String) {
  let assert Ok(re) = regexp.from_string("^[a-zA-Z0-9._~%-]+$")

  case regexp.check(re, value) {
    True -> Ok(Constant(value))
    False -> Error("Invalid constant value " <> value)
  }
}

@internal
pub fn value(input: Constant) -> String {
  input.value
}
