import gleam/regexp
import gleam/string

pub opaque type Fixed {
  Fixed(value: String)
}

pub fn new(value: String) -> Result(Fixed, String) {
  let assert Ok(re) = regexp.from_string("^[a-zA-Z0-9._~%-]+$")

  let candidate = string.lowercase(value)

  case regexp.check(re, candidate) {
    True -> Ok(Fixed(candidate))
    False -> Error("Invalid fixed value " <> value)
  }
}

pub fn unsafe(value: String) {
  Fixed(value)
}

pub fn value(input: Fixed) -> String {
  input.value
}
