import filepath
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import justin
import simplifile

const indent = "  "

pub type Segment {
  Lit(val: String)
  Str(name: String)
  Int(name: String)
}

pub type RouteDef {
  RouteDef(name: String, path: List(Segment))
}

type ValidSegment {
  ValidLit(val: String)
  ValidStr(name: String)
  ValidInt(name: String)
}

type ValidRouteDef {
  ValidRouteDef(name: String, segments: List(ValidSegment))
}

pub fn main(definitions: List(RouteDef), output_path: String) {
  use definitions <- result.try(prepare_definitions(definitions))

  let generated_code =
    generate_imports()
    <> "\n\n"
    <> generate_types(definitions)
    <> "\n\n"
    <> generate_segments_to_route(definitions)
    <> "\n\n"
    <> generate_route_to_path(definitions)
    <> "\n\n"
    <> generate_helpers()

  let output_dir = filepath.directory_name(output_path)
  let _ = simplifile.create_directory_all(output_dir)
  let _ = simplifile.write(output_path, generated_code)

  Ok(Nil)
}

fn prepare_definitions(
  definitions: List(RouteDef),
) -> Result(List(ValidRouteDef), String) {
  list.try_map(definitions, prepare_definition)
}

fn prepare_definition(def: RouteDef) {
  let name = justin.pascal_case(def.name)

  let sanitized_segments =
    def.path
    |> list.map(fn(segment) {
      case segment {
        Lit(value) -> ValidLit(value)
        Str(name) -> ValidStr(justin.snake_case(name))
        Int(name) -> ValidInt(justin.snake_case(name))
      }
    })

  let segment_names =
    sanitized_segments
    |> list.filter_map(fn(segment) {
      case segment {
        ValidLit(_) -> Error(Nil)
        ValidStr(name) -> Ok(name)
        ValidInt(name) -> Ok(name)
      }
    })

  case list.length(segment_names) == set.size(set.from_list(segment_names)) {
    True -> ValidRouteDef(name:, segments: sanitized_segments) |> Ok
    False -> Error("Route " <> def.name <> " has duplicate parameter names")
  }
}

fn generate_imports() {
  ["import gleam/int", "import gleam/result"]
  |> string.join("\n")
}

fn generate_types(definitions: List(ValidRouteDef)) {
  let variants =
    definitions
    |> list.map(generate_type_variant)
    |> string.join("\n")

  "pub type Route {\n" <> variants <> "\n}"
}

fn generate_type_variant(def: ValidRouteDef) {
  let params =
    def.segments
    |> list.filter_map(generate_type_variant_param)
    |> string.join(", ")

  "  " <> def.name <> "(" <> params <> ")"
}

fn generate_type_variant_param(segment: ValidSegment) {
  case segment {
    ValidInt(name) -> Ok(name <> ": Int")
    ValidLit(_) -> Error(Nil)
    ValidStr(name) -> Ok(name <> ": String")
  }
}

fn generate_segments_to_route(definitions: List(ValidRouteDef)) {
  let segments_to_route_cases =
    definitions
    |> list.map(generate_segments_to_route_case)
    |> string.join("\n")

  string.trim(
    "pub fn segments_to_route(segments: List(String)) -> Result(Route, Nil) {\n"
    <> "  case segments {\n"
    <> segments_to_route_cases
    <> "\n    _ -> Error(Nil)\n"
    <> "  }\n"
    <> "}",
  )
}

fn generate_segments_to_route_case(def: ValidRouteDef) {
  let matched_params =
    def.segments
    |> list.map(fn(seg) {
      case seg {
        ValidLit(val) -> "\"" <> val <> "\""
        ValidStr(name) -> name
        ValidInt(name) -> name
      }
    })
    |> string.join(", ")

  let left = "[" <> matched_params <> "]"

  let match_right_inner =
    def.segments
    |> list.filter_map(fn(seg) {
      case seg {
        ValidLit(_) -> Error(Nil)
        ValidStr(name) -> Ok(name)
        ValidInt(name) -> Ok(name)
      }
    })
    |> string.join(", ")

  let match_right_inner = case match_right_inner {
    "" -> ""
    match_right_inner -> {
      "(" <> match_right_inner <> ")"
    }
  }

  let right = def.name <> match_right_inner <> " |> Ok"

  let right =
    list.fold(def.segments, right, fn(acc, segment) {
      case segment {
        ValidLit(_) -> acc
        ValidStr(_) -> acc
        ValidInt(name) -> {
          "with_int(" <> name <> ", fn(" <> name <> ") { " <> acc <> " })"
        }
      }
    })

  indent <> indent <> left <> " -> " <> right
}

fn generate_route_to_path(definitions: List(ValidRouteDef)) {
  let route_to_path_cases =
    definitions
    |> list.map(generate_route_to_path_case)
    |> string.join("\n")

  string.trim(
    "pub fn route_to_path(route: Route) -> String {\n"
    <> indent
    <> "case route {\n"
    <> route_to_path_cases
    <> "\n  }\n"
    <> "}",
  )
}

fn generate_route_to_path_case(def: ValidRouteDef) {
  let variant_params =
    def.segments
    |> list.filter_map(fn(seg) {
      case seg {
        ValidLit(_) -> Error(Nil)
        ValidStr(name) -> Ok(name)
        ValidInt(name) -> Ok(name)
      }
    })
    |> string.join(", ")

  let path =
    def.segments
    |> list.map(fn(seg) {
      case seg {
        ValidLit(val) -> "\"" <> val <> "/\""
        ValidStr(name) -> name
        ValidInt(name) -> "int.to_string(" <> name <> ")"
      }
    })
    |> string.join(" <> ")

  let path = case path {
    "" -> "\"/\""
    path -> "\"/\" <> " <> path
  }

  indent <> indent <> def.name <> "(" <> variant_params <> ") -> " <> path
}

fn generate_helpers() {
  "
fn with_int(str: String, fun) {
    int.parse(str)
    |> result.try(fun)
}
"
}
