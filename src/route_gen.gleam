import filepath
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
  use definitions <- result.try(prepare_definitions(definitions))

  let types =
    generate_type_and_subtypes("", definitions)
    |> result.unwrap("")

  let segments_to_route =
    generate_segments_and_subs_to_route("", definitions)
    |> result.unwrap("")

  let routes_to_path =
    generate_route_and_subs_to_path("", definitions)
    |> result.unwrap("")

  let generated_code =
    generate_imports()
    <> "\n\n"
    <> types
    <> segments_to_route
    <> "\n\n"
    <> routes_to_path
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

fn generate_imports() {
  ["import gleam/int", "import gleam/result"]
  |> string.join("\n")
}

fn generate_type_and_subtypes(
  namespace: String,
  definitions: List(ValidRouteDef),
) {
  case list.is_empty(definitions) {
    True -> Error(Nil)
    False -> {
      let sub_types =
        list.filter_map(definitions, fn(def) {
          generate_type_and_subtypes(def.name, def.sub)
        })
        |> string.join("\n")

      let out = generate_type(namespace, definitions) <> "\n\n" <> sub_types

      Ok(out)
    }
  }
}

fn generate_type(namespace: String, definitions: List(ValidRouteDef)) {
  let variants =
    definitions
    |> list.map(generate_type_variant(namespace, _))
    |> string.join("\n")

  "pub type " <> namespace <> "Route {\n" <> variants <> "\n}"
}

fn generate_type_variant(namespace: String, def: ValidRouteDef) {
  let params =
    def.segments
    |> list.filter_map(generate_type_variant_param)
    |> string.join(", ")

  let sub = case list.is_empty(def.sub) {
    True -> ""
    False -> ", sub: " <> namespace <> def.name <> "Route"
  }

  "  " <> namespace <> def.name <> "(" <> params <> sub <> ")"
}

fn generate_type_variant_param(segment: ValidSegment) {
  case segment {
    ValidInt(name) -> Ok(name <> ": Int")
    ValidLit(_) -> Error(Nil)
    ValidStr(name) -> Ok(name <> ": String")
  }
}

fn generate_segments_and_subs_to_route(
  namespace: String,
  definitions: List(ValidRouteDef),
) {
  case list.is_empty(definitions) {
    True -> Error(Nil)
    False -> {
      let sub_types =
        list.filter_map(definitions, fn(def) {
          generate_segments_and_subs_to_route(namespace <> def.name, def.sub)
        })
        |> string.join("\n")

      let out =
        generate_segments_to_route(namespace, definitions)
        <> "\n\n"
        <> sub_types

      Ok(out)
    }
  }
}

fn generate_segments_to_route(
  namespace: String,
  definitions: List(ValidRouteDef),
) {
  let segments_to_route_cases =
    definitions
    |> list.map(generate_segments_to_route_case(namespace, _))
    |> string.join("\n")

  let fn_name = case namespace {
    "" -> "segments_to_route"
    _ -> justin.camel_case(namespace) <> "_segments_to_route"
  }

  string.trim(
    "pub fn "
    <> fn_name
    <> "(segments: List(String)) -> Result("
    <> namespace
    <> "Route, Nil) {\n"
    <> "  case segments {\n"
    <> segments_to_route_cases
    <> "\n    _ -> Error(Nil)\n"
    <> "  }\n"
    <> "}",
  )
}

fn generate_segments_to_route_case(namespace: String, def: ValidRouteDef) {
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

  let matched_params = case list.is_empty(def.sub) {
    True -> matched_params
    False -> matched_params <> ", ..rest"
  }

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
    |> fn(params) {
      case list.is_empty(def.sub) {
        True -> params
        False -> list.append(params, ["sub"])
      }
    }
    |> string.join(", ")

  let match_right_inner = case match_right_inner {
    "" -> ""
    match_right_inner -> {
      "(" <> match_right_inner <> ")"
    }
  }

  let right = case list.is_empty(def.sub) {
    True -> {
      namespace <> def.name <> match_right_inner <> " |> Ok"
    }
    False -> {
      let fn_name =
        justin.snake_case(namespace <> def.name <> "_segments_to_route")

      fn_name <> "(rest) |> result.map(fn(sub) {
" <> namespace <> def.name <> match_right_inner <> "
        })"
    }
  }

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

fn generate_route_and_subs_to_path(namespace: String, defs: List(ValidRouteDef)) {
  case list.is_empty(defs) {
    True -> Error(Nil)
    False -> {
      let sub_types =
        list.filter_map(defs, fn(def) {
          generate_route_and_subs_to_path(namespace <> def.name, def.sub)
        })
        |> string.join("\n")

      let out = generate_route_to_path(namespace, defs) <> "\n\n" <> sub_types
      Ok(out)
    }
  }
}

fn generate_route_to_path(namespace: String, definitions: List(ValidRouteDef)) {
  let route_to_path_cases =
    definitions
    |> list.map(generate_route_to_path_case(namespace, _))
    |> string.join("\n")

  let fn_name = case namespace {
    "" -> "route_to_path"
    _ -> justin.snake_case(namespace) <> "_route_to_path"
  }

  string.trim(
    "pub fn "
    <> fn_name
    <> "(route: "
    <> namespace
    <> "Route) -> String {\n"
    <> indent
    <> "case route {\n"
    <> route_to_path_cases
    <> "\n  }\n"
    <> "}",
  )
}

fn generate_route_to_path_case(namespace: String, def: ValidRouteDef) {
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

  let variant_params = case list.is_empty(def.sub) {
    True -> variant_params
    False -> {
      variant_params <> ", sub"
    }
  }

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

  let path = case list.is_empty(def.sub) {
    True -> path
    False ->
      path
      <> " <> "
      <> justin.snake_case(namespace <> def.name)
      <> "_route_to_path(sub)"
  }

  let path = case path {
    "" -> "\"/\""
    path -> "\"/\" <> " <> path
  }

  indent
  <> indent
  <> namespace
  <> def.name
  <> "("
  <> variant_params
  <> ") -> "
  <> path
}

fn generate_helpers() {
  "
fn with_int(str: String, fun) {
    int.parse(str)
    |> result.try(fun)
}
"
}
