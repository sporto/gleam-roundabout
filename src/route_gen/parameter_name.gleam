import gleam/regexp
import justin

@internal
pub opaque type ParameterName {
  ParameterName(name: String)
}

@internal
pub fn new(input: String) -> Result(ParameterName, String) {
  let assert Ok(re) = regexp.from_string("^[a-z][a-z0-9 _-]*$")

  let candidate = justin.snake_case(input)

  case regexp.check(re, candidate) {
    True -> Ok(ParameterName(justin.snake_case(input)))
    False -> Error("Invalid parameter name " <> input)
  }
}

@internal
pub fn to_string(p: ParameterName) -> String {
  p.name
}
