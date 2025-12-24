import filepath
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import justin
import route_gen/generate
import route_gen/parse
import route_gen/types
import simplifile

const indent = "  "

pub type Segment {
  Lit(val: String)
  Str(name: String)
  Int(name: String)
}

pub type RouteDef {
  RouteDef(name: String, path: List(Segment), sub: List(RouteDef))
}

type ValidSegment {
  ValidLit(val: String)
  ValidStr(name: String)
  ValidInt(name: String)
}

type ValidRouteDef {
  ValidRouteDef(
    name: String,
    segments: List(ValidSegment),
    sub: List(ValidRouteDef),
  )
}

pub fn main(definitions: List(RouteDef), output_path: String) {
  let definitions_2 =
    definitions
    |> list.map(route_def_to_internal)

  use contributions <- result.try(parse.prepare_contributions(
    option.None,
    definitions_2,
  ))

  use root <- result.try(parse.parse(definitions_2))

  use definitions <- result.try(prepare_definitions(definitions))

  let types =
    generate.generate_type(root)
    |> result.unwrap("")

  let segments_to_route =
    generate.generate_segments_to_route(root)
    |> result.unwrap("")

  let routes_to_path =
    generate.generate_route_to_path(root)
    |> result.unwrap("")

  let helpers = generate.generate_helpers(root)

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

fn route_def_to_internal(def: RouteDef) -> types.InputDef {
  let path =
    list.map(def.path, fn(seg) {
      case seg {
        Lit(val) -> types.Lit(val)
        Str(val) -> types.Str(val)
        Int(val) -> types.Int(val)
      }
    })

  let sub = list.map(def.sub, route_def_to_internal)

  types.InputDef(name: def.name, path:, sub:)
}

fn prepare_definitions(
  definitions: List(RouteDef),
) -> Result(List(ValidRouteDef), String) {
  use definitions <- result.try(list.try_map(definitions, prepare_definition))

  use definitions <- result.try(assert_no_duplicate_variant_names(definitions))

  Ok(definitions)
}

fn assert_no_duplicate_variant_names(definitions: List(ValidRouteDef)) {
  let variant_names = list.map(definitions, fn(def) { def.name })
  let as_set = set.from_list(variant_names)

  case list.length(variant_names) == set.size(as_set) {
    True -> Ok(definitions)
    False -> Error("Routes contain duplicate names")
  }
}

fn prepare_definition(def: RouteDef) {
  let name = justin.pascal_case(def.name)

  let segments =
    def.path
    |> list.map(fn(segment) {
      case segment {
        Lit(value) -> ValidLit(value)
        Str(name) -> ValidStr(justin.snake_case(name))
        Int(name) -> ValidInt(justin.snake_case(name))
      }
    })

  use segments <- result.try(assert_no_duplicate_param_names(name, segments))

  use sub <- result.try(prepare_definitions(def.sub))

  ValidRouteDef(name:, segments:, sub:) |> Ok
}

fn assert_no_duplicate_param_names(name, segments) {
  let segment_names =
    segments
    |> list.filter_map(fn(segment) {
      case segment {
        ValidLit(_) -> Error(Nil)
        ValidStr(name) -> Ok(name)
        ValidInt(name) -> Ok(name)
      }
    })

  let as_set = set.from_list(segment_names)

  case list.length(segment_names) == set.size(as_set) {
    True -> Ok(segments)
    False -> Error("Route " <> name <> " has duplicate parameter names")
  }
}
