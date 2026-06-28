import gleam/list
import gleam/regexp
import gleam/string
import justin

pub type Kind {
  Int
  Str
}

pub opaque type Parameter {
  Parameter(name: String, kind: Kind)
}

pub fn new(name: String, kind: Kind) -> Result(Parameter, String) {
  let assert Ok(re) = regexp.from_string("^[a-z][a-z0-9 _-]*$")

  let candidate = justin.snake_case(name)

  case regexp.check(re, candidate) {
    True -> Ok(Parameter(justin.snake_case(name), kind))
    False -> Error("Invalid parameter name " <> name)
  }
}

pub fn unsafe(name: String, kind: Kind) {
  Parameter(name, kind)
}

pub fn unsafe_int(name: String) {
  Parameter(name, Int)
}

pub fn unsafe_str(name: String) {
  Parameter(name, Str)
}

pub fn name(p: Parameter) -> String {
  p.name
}

pub fn qualified_name(
  ancestors: List(String),
  node_name: String,
  p: Parameter,
) -> String {
  ancestors
  |> list.reverse
  |> list.filter(fn(a) { !string.is_empty(a) })
  |> list.append([node_name, p.name])
  |> string.join("_")
  |> justin.snake_case
}

pub fn kind(p: Parameter) {
  p.kind
}

pub fn prepend_name(namespace: String, parameter: Parameter) {
  case namespace {
    "" -> parameter
    _ -> Parameter(..parameter, name: namespace <> "_" <> parameter.name)
  }
}

pub fn print_type_name(p: Parameter) {
  case p.kind {
    Str -> "String"
    Int -> "Int"
  }
}

pub fn print_name_and_type(p: Parameter) {
  p.name <> ": " <> print_type_name(p)
}
