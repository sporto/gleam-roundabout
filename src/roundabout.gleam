import filepath
import glam/doc
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import justin
import roundabout/internal/fixed
import roundabout/internal/generate_helpers
import roundabout/internal/generate_other
import roundabout/internal/generate_route_to_path
import roundabout/internal/generate_segments_to_route
import roundabout/internal/generate_types
import roundabout/internal/node
import roundabout/internal/parameter
import roundabout/internal/type_name
import simplifile

/// Path segments
pub opaque type Segment {
  Fixed(value: String)
  Str(name: String)
  Int(name: String)
}

/// The route definition
pub opaque type Route {
  Route(name: String, path: List(Segment), children: List(Route))
}

/// Make a route defintion
///
/// e.g.
/// ```gleam
/// route("users", [fixed("users"), int("user_id")], [])
/// ```
///
/// `name` is the name for this route, this will be used for generating the variant names and helper names.
///
/// `path` defines the url segments e.g. /users/1.
///
/// `children` generates sub types for nested routes, this is useful for middleware.
pub fn route(
  name name: String,
  path path: List(Segment),
  children children: List(Route),
) {
  Route(name:, path:, children:)
}

/// A path segment that is constant
///
/// e.g.
/// ```gleam
/// [fixed("users"), str("user_id")]
/// ```
pub fn fixed(value: String) {
  Fixed(value)
}

/// A path segment that should resolve to a string
///
/// e.g.
/// ```gleam
/// [fixed("users"), str("user_id")]
/// ```
pub fn str(name: String) {
  Str(name)
}

/// A path segment that should resolve to an integer
///
/// e.g.
/// ```gleam
/// [fixed("users"), int("user_id")]
/// ```
pub fn int(name: String) {
  Int(name)
}

/// Generate the routes file
///
/// ```gleam
/// roundabout.main(route_definitions, "src/my_app/generated/routes")
/// ```
pub fn main(definitions: List(Route), output_path: String) {
  use root <- result.try(parse(definitions))

  let output_path = case string.ends_with(output_path, ".gleam") {
    True -> output_path
    False -> output_path <> ".gleam"
  }

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
  let _ = simplifile.write(output_path, generated_code)

  Ok(Nil)
}

@internal
pub fn parse(definitions: List(Route)) -> Result(node.Node, String) {
  use children <- result.try(parse_definitions("root", definitions))

  let root =
    node.Node(children:, info: node.Info(name: type_name.unsafe(""), path: []))

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
    False -> Error("Route " <> parent_name <> " contains duplicate route names")
  }
}

fn parse_definition(definition: Route) {
  use info <- result.try(parse_definition_info(definition))

  use children <- result.try(parse_definitions(
    definition.name,
    definition.children,
  ))

  node.Node(info:, children:) |> Ok
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
        Fixed(val) -> {
          fixed.new(val)
          |> result.map(node.SegFixed)
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
        Fixed(_) -> Error(Nil)
        Str(val) -> Ok(justin.snake_case(val))
        Int(val) -> Ok(justin.snake_case(val))
      }
    })

  let as_set = set.from_list(segment_names)

  case list.length(segment_names) == set.size(as_set) {
    True -> Ok(segments)
    False -> Error("Route " <> node_name <> " contains duplicate segment names")
  }
}
