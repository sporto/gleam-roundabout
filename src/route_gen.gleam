import filepath
import gleam/list
import gleam/result
import route_gen/generate
import route_gen/parse
import route_gen/types
import simplifile

pub type Segment {
  Lit(val: String)
  Str(name: String)
  Int(name: String)
}

pub type RouteDef {
  RouteDef(name: String, path: List(Segment), sub: List(RouteDef))
}

pub fn main(definitions: List(RouteDef), output_path: String) {
  let definitions_2 =
    definitions
    |> list.map(route_def_to_internal)

  use root <- result.try(parse.parse(definitions_2))

  let types =
    generate.generate_type([], root)
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
