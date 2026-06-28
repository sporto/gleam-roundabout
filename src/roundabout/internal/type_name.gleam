import gleam/regexp
import justin

pub opaque type TypeName {
  TypeName(name: String)
}

pub fn new(name: String) -> Result(TypeName, String) {
  let assert Ok(re) = regexp.from_string("^[A-Z][a-zA-Z0-9]*$")

  let candidate = justin.pascal_case(name)

  case regexp.check(re, candidate) {
    True -> Ok(TypeName(candidate))
    False -> Error("Invalid type name " <> name)
  }
}

pub fn unsafe(value: String) {
  TypeName(value)
}

pub fn name(input: TypeName) -> String {
  input.name
}

pub fn snake(input: TypeName) -> String {
  input.name |> justin.snake_case
}

pub fn is_root(input: TypeName) {
  input.name == ""
}
