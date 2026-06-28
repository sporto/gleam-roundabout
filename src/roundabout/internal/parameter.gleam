import gleam/regexp
import gleam/string
import justin
import roundabout/internal/ancestors.{type Ancestors}
import roundabout/internal/qualified.{type Qualified, type Unqualified}
import roundabout/internal/type_name

pub type Kind {
  Int
  Str
}

pub opaque type Parameter(qua) {
  Parameter(name: String, kind: Kind)
}

pub fn new(name: String, kind: Kind) -> Result(Parameter(Unqualified), String) {
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

pub fn qualify_name(
  ancestors: Ancestors(type_name.TypeName),
  node_name: type_name.TypeName,
  p: Parameter(Unqualified),
) -> Parameter(Qualified) {
  let qualified_name =
    ancestors
    |> ancestors.filter(fn(a) { !type_name.is_root(a) })
    |> ancestors.push(node_name)
    |> ancestors.map(type_name.name)
    |> ancestors.push(p.name)
    |> ancestors.to_list
    |> string.join("_")
    |> justin.snake_case

  Parameter(..p, name: qualified_name)
}

pub fn kind(p: Parameter(qua)) {
  p.kind
}

pub fn print_type_name(p: Parameter(qua)) {
  case p.kind {
    Str -> "String"
    Int -> "Int"
  }
}

pub fn print_name_qualified(p: Parameter(Qualified)) -> String {
  p.name
}

pub fn print_name(p: Parameter(qua)) -> String {
  p.name
}

pub fn print_name_and_type(p: Parameter(qua)) {
  print_name(p) <> ": " <> print_type_name(p)
}
