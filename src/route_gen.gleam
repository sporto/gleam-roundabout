import filepath
import gleam/list
import gleam/result
import gleam/set
import justin
import route_gen/generate
import route_gen/types
import simplifile

pub type Segment {
  Lit(val: String)
  Str(name: String)
  Int(name: String)
}

pub type Route {
  Route(name: String, path: List(Segment), sub: List(Route))
}

pub fn main(definitions: List(Route), output_path: String) {
  use root <- result.try(parse(definitions))

  let types =
    generate.generate_type_rec([], root)
    |> result.unwrap("")

  let segments_to_route =
    generate.generate_segments_to_route_rec([], root)
    |> result.unwrap("")

  let routes_to_path =
    generate.generate_route_to_path_rec([], root)
    |> result.unwrap("")

  let helpers = generate.generate_helpers_rec([], root)

  let utils = generate.generate_utils()

  let generated_code =
    generate.generate_imports()
    <> types
    <> segments_to_route
    <> routes_to_path
    <> helpers
    <> utils

  let output_dir = filepath.directory_name(output_path)
  let _ = simplifile.create_directory_all(output_dir)
  let _ = simplifile.write(output_path, generated_code)

  Ok(Nil)
}

pub fn parse(definitions: List(Route)) {
  use nodes <- result.try(parse_definitions(definitions))

  let root =
    types.Node(children: nodes, info: types.Info(name: "", segments: []))

  Ok(root)
}

@internal
pub fn parse_definitions(
  definitions: List(Route),
) -> Result(List(types.Node), String) {
  use nodes <- result.try(list.try_map(definitions, parse_definition))

  use nodes <- result.try(assert_no_duplicate_variant_names(nodes))

  Ok(nodes)
}

fn assert_no_duplicate_variant_names(nodes: List(types.Node)) {
  let variant_names =
    list.map(nodes, fn(item) { justin.snake_case(item.info.name) })

  let as_set = set.from_list(variant_names)

  case list.length(variant_names) == set.size(as_set) {
    True -> Ok(nodes)
    False -> Error("Routes contain duplicate names")
  }
}

fn parse_definition(definition: Route) {
  let info = parse_definition_info(definition)

  use children <- result.try(parse_definitions(definition.sub))

  types.Node(info:, children:) |> Ok
}

fn parse_definition_info(definition: Route) {
  let segments =
    definition.path
    |> list.map(fn(seg) {
      case seg {
        Lit(val) -> types.SegLit(val)
        Str(val) -> types.SegStr(val)
        Int(val) -> types.SegInt(val)
      }
    })

  types.Info(name: definition.name, segments:)
}
