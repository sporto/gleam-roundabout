import gleam/regexp
import justin

@internal
pub type Kind {
  Int
  Str
}

@internal
pub opaque type Parameter {
  Parameter(name: String, kind: Kind)
}

@internal
pub fn new(name: String, kind: Kind) -> Result(Parameter, String) {
  let assert Ok(re) = regexp.from_string("^[a-z][a-z0-9 _-]*$")

  let candidate = justin.snake_case(name)

  case regexp.check(re, candidate) {
    True -> Ok(Parameter(justin.snake_case(name), kind))
    False -> Error("Invalid parameter name " <> name)
  }
}

@internal
pub fn unsafe(name: String, kind: Kind) {
  Parameter(name, kind)
}

@internal
pub fn unsafe_int(name: String) {
  Parameter(name, Int)
}

@internal
pub fn name(p: Parameter) -> String {
  p.name
}

@internal
pub fn kind(p: Parameter) {
  p.kind
}

@internal
pub fn type_name(p: Parameter) {
  case p.kind {
    Str -> "String"
    Int -> "Int"
  }
}

@internal
pub fn full(p: Parameter) {
  p.name <> ": " <> type_name(p)
}
