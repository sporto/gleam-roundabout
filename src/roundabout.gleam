import filepath
import glam/doc
import gleam/list
import gleam/result
import gleam/set
import justin
import roundabout/internal/constant
import roundabout/internal/generate_helpers
import roundabout/internal/generate_other
import roundabout/internal/generate_route_to_path
import roundabout/internal/generate_segments_to_route
import roundabout/internal/generate_types
import roundabout/internal/node
import roundabout/internal/parameter
import roundabout/internal/type_name
import simplifile

pub type Segment {
  Lit(val: String)
  Str(name: String)
  Int(name: String)
}

pub type Route {
  Route(name: String, path: List(Segment), sub: List(Route))
}

/// Generate the routes file
///
/// ```
/// roundabout.main(route_definitions, "src/generated/routes")
/// ```
pub fn main(definitions: List(Route), output_path: String) {
  use root <- result.try(parse(definitions))

  let types = generate_types.generate_type_rec([], root)

  let segments_to_route =
    generate_segments_to_route.generate_segments_to_route_rec([], root)

  let routes_to_path =
    generate_route_to_path.generate_route_to_path_rec([], root)

  let helpers = generate_helpers.generate_helpers_rec([], root)

  let utils = generate_other.generate_utils()

  let all =
    doc.concat([
      generate_other.generate_header(),
      generate_other.generate_imports(),
      types,
      segments_to_route,
      routes_to_path,
      helpers,
      utils,
    ])

  let generated_code = all |> doc.to_string(80)

  let output_dir = filepath.directory_name(output_path)
  let _ = simplifile.create_directory_all(output_dir)
  let _ = simplifile.write(output_path <> ".gleam", generated_code)

  Ok(Nil)
}

@internal
pub fn parse(definitions: List(Route)) -> Result(node.Node, String) {
  use sub <- result.try(parse_definitions("root", definitions))

  let root =
    node.Node(sub:, info: node.Info(name: type_name.unsafe(""), path: []))

  Ok(root)
}

@internal
pub fn parse_definitions(
  parent_name: String,
  definitions: List(Route),
) -> Result(List(node.Node), String) {
  use nodes <- result.try(list.try_map(definitions, parse_definition))

  use nodes <- result.try(assert_no_duplicate_variant_names(parent_name, nodes))

  Ok(nodes)
}

fn assert_no_duplicate_variant_names(
  parent_name: String,
  nodes: List(node.Node),
) {
  let variant_names =
    list.map(nodes, fn(item) { type_name.snake(item.info.name) })

  let as_set = set.from_list(variant_names)

  case list.length(variant_names) == set.size(as_set) {
    True -> Ok(nodes)
    False -> Error("Route " <> parent_name <> " contain duplicate route names")
  }
}

fn parse_definition(definition: Route) {
  use info <- result.try(parse_definition_info(definition))

  use sub <- result.try(parse_definitions(definition.name, definition.sub))

  node.Node(info:, sub:) |> Ok
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
        Lit(val) -> {
          constant.new(val)
          |> result.map(node.SegLit)
        }
        Str(val) -> {
          parameter.new(val, parameter.Str)
          |> result.map(node.SegParam)
        }
        Int(val) -> {
          parameter.new(val, parameter.Int)
          |> result.map(node.SegParam)
        }
      }
    })

  use name <- result.try(type_name.new(input.name))

  use path <- result.try(path_result)

  node.Info(name:, path:) |> Ok
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
