import gleam/regexp
import justin

@internal
pub opaque type TypeName {
  TypeName(name: String)
}

@internal
pub fn new(name: String) -> Result(TypeName, String) {
  let assert Ok(re) = regexp.from_string("^[A-Z][a-zA-Z0-9]*$")

  let candidate = justin.pascal_case(name)

  case regexp.check(re, candidate) {
    True -> Ok(TypeName(candidate))
    False -> Error("Invalid type name " <> name)
  }
}

@internal
pub fn unsafe(value: String) {
  TypeName(value)
}

@internal
pub fn name(input: TypeName) -> String {
  input.name
}

@internal
pub fn snake(input: TypeName) -> String {
  input.name |> justin.snake_case
}
