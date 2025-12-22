import filepath
import gleam/int
import gleam/list
import gleam/string
import gleam/uri
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

pub fn main(definitions: List(RouteDef), output_path: String) {
  let definitions = prepare_definitions(definitions)

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

fn prepare_definitions(definitions: List(RouteDef)) {
  list.map(definitions, fn(def) {
    RouteDef(..def, name: justin.pascal_case(def.name))
  })
}

fn generate_imports() {
  ["import gleam/int", "import gleam/result"]
  |> string.join("\n")
}

fn generate_types(definitions: List(RouteDef)) {
  let variants =
    definitions
    |> list.map(generate_type_variant)
    |> string.join("\n")

  "pub type Route {\n" <> variants <> "\n}"
}

fn generate_type_variant(def: RouteDef) {
  let params =
    def.path
    |> list.filter_map(generate_type_variant_param)
    |> string.join(", ")

  "  " <> def.name <> "(" <> params <> ")"
}

fn generate_type_variant_param(segment: Segment) {
  case segment {
    Int(name) -> Ok(name <> ": Int")
    Lit(_) -> Error(Nil)
    Str(name) -> Ok(name <> ": String")
  }
}

fn generate_segments_to_route(definitions: List(RouteDef)) {
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

fn generate_segments_to_route_case(def: RouteDef) {
  let matched_params =
    def.path
    |> list.map(fn(seg) {
      case seg {
        Lit(val) -> "\"" <> val <> "\""
        Str(name) -> name
        Int(name) -> name
      }
    })
    |> string.join(", ")

  let left = "[" <> matched_params <> "]"

  let match_right_inner =
    def.path
    |> list.filter_map(fn(seg) {
      case seg {
        Lit(_) -> Error(Nil)
        Str(name) -> Ok(name)
        Int(name) -> Ok(name)
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
    list.fold(def.path, right, fn(acc, segment) {
      case segment {
        Lit(_) -> acc
        Str(_) -> acc
        Int(name) -> {
          "with_int(" <> name <> ", fn(" <> name <> ") { " <> acc <> " })"
        }
      }
    })

  indent <> indent <> left <> " -> " <> right
}

fn generate_route_to_path(definitions: List(RouteDef)) {
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

fn generate_route_to_path_case(def: RouteDef) {
  let variant_params =
    def.path
    |> list.filter_map(fn(seg) {
      case seg {
        Lit(_) -> Error(Nil)
        Str(name) -> Ok(name)
        Int(name) -> Ok(name)
      }
    })
    |> string.join(", ")

  let path =
    def.path
    |> list.map(fn(seg) {
      case seg {
        Lit(val) -> "\"" <> val <> "/\""
        Str(name) -> name
        Int(name) -> "int.to_string(" <> name <> ")"
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
