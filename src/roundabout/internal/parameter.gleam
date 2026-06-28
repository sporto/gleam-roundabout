import gleam/regexp
import gleam/list
import gleam/string
import gleam/result
import justin
import roundabout/internal/ancestors.{type Ancestors}
import roundabout/internal/qualified.{type Qualified, type Unqualified}
import roundabout/internal/name

pub type Kind {
  Int
  Str
}

pub opaque type Parameter(qua) {
  Parameter(name: name.Name, kind: Kind)
}

pub fn new(name: String, kind: Kind) -> Result(Parameter(Unqualified), String) {
  use name <- result.try(name.new(name))

  Ok(Parameter(name, kind))
}

pub fn unsafe(name: String, kind: Kind) {
  Parameter(name.unsafe(name), kind)
}

pub fn unsafe_int(name: String) {
  Parameter(name.unsafe(name), Int)
}

pub fn unsafe_str(name: String) {
  Parameter(name.unsafe(name), Str)
}

pub fn qualify_name(
  ancestors: Ancestors(name.Name),
  node_name: name.Name,
  p: Parameter(Unqualified),
) -> Parameter(Qualified) {
  let qualified_name =
    ancestors
    |> ancestors.filter(fn(a) { !name.is_root(a) })
    |> ancestors.push(node_name)
    |> ancestors.push(p.name)
    |> ancestors.to_list
    |> list.map(name.parameter_name)
    |> string.join("-")

  Parameter(..p, name: name.unsafe(qualified_name))
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
  name.parameter_name(p.name)
}

pub fn print_name(p: Parameter(qua)) -> String {
  name.parameter_name(p.name)
}

pub fn print_name_and_type(p: Parameter(qua)) {
  print_name(p) <> ": " <> print_type_name(p)
}
