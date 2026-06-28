import gleam/regexp
import justin

pub type AsName {
  AsTypeName
  AsParameterName
}

pub opaque type Name {
  Name(name: String)
}

pub fn new(name: String) -> Result(Name, String) {
  let assert Ok(re) = regexp.from_string("^[a-zA-Z][a-zA-Z0-9 _-]*$")

  let candidate = justin.kebab_case(name)

  case regexp.check(re, candidate) {
    True -> Ok(Name(candidate))
    False -> Error("Invalid name " <> name)
  }
}

pub fn unsafe(value: String) {
  Name(value)
}

pub fn type_name(input: Name) -> String {
 justin.pascal_case(input.name)
}

pub fn parameter_name(input: Name) -> String {
  justin.snake_case(input.name)
}

pub fn is_root(input: Name) {
  input.name == ""
}
