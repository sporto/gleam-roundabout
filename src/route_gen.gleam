import filepath
import gleam/list
import gleam/result
import gleam/set
import justin
import route_gen/generate
import route_gen/parameter_name
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

@internal
pub fn parse(definitions: List(Route)) -> Result(types.Node, String) {
  use sub <- result.try(parse_definitions("root", definitions))

  let root = types.Node(sub:, info: types.Info(name: "", path: []))

  Ok(root)
}

@internal
pub fn parse_definitions(
  parent_name: String,
  definitions: List(Route),
) -> Result(List(types.Node), String) {
  use nodes <- result.try(list.try_map(definitions, parse_definition))

  use nodes <- result.try(assert_no_duplicate_variant_names(parent_name, nodes))

  Ok(nodes)
}

fn assert_no_duplicate_variant_names(
  parent_name: String,
  nodes: List(types.Node),
) {
  let variant_names =
    list.map(nodes, fn(item) { justin.snake_case(item.info.name) })

  let as_set = set.from_list(variant_names)

  case list.length(variant_names) == set.size(as_set) {
    True -> Ok(nodes)
    False -> Error("Route " <> parent_name <> " contain duplicate route names")
  }
}

fn parse_definition(definition: Route) {
  use info <- result.try(parse_definition_info(definition))

  use sub <- result.try(parse_definitions(definition.name, definition.sub))

  types.Node(info:, sub:) |> Ok
}

fn parse_definition_info(input: Route) {
  use input_path <- result.try(assert_no_duplicate_segment_names(
    input.name,
    input.path,
  ))

  let path_result =
    input_path
    |> list.try_map(fn(seg) {
      case seg {
        Lit(val) -> types.SegLit(val) |> Ok
        Str(val) -> {
          parameter_name.new(val)
          |> result.map(types.SegStr)
        }
        Int(val) -> {
          parameter_name.new(val)
          |> result.map(types.SegInt)
        }
      }
    })

  use path <- result.try(path_result)

  types.Info(name: input.name, path:) |> Ok
}

fn assert_no_duplicate_segment_names(node_name: String, segments: List(Segment)) {
  let segment_names =
    list.filter_map(segments, fn(seg) {
      case seg {
        Lit(_) -> Error(Nil)
        Str(val) -> Ok(justin.snake_case(val))
        Int(val) -> Ok(justin.snake_case(val))
      }
    })

  let as_set = set.from_list(segment_names)

  case list.length(segment_names) == set.size(as_set) {
    True -> Ok(segments)
    False -> Error("Route " <> node_name <> " contain duplicate segment names")
  }
}
