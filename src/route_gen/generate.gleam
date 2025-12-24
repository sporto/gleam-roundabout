import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import justin
import route_gen/types.{type Info, type InputDef, type Node, Info, Node}

const indent = "  "

const block_break = "\n\n"

@internal
pub fn generate_imports() {
  ["import gleam/int", "import gleam/result"]
  |> string.join("\n")
  <> block_break
}

/// Generates:
/// ```
/// pub type Route {
///   Home
///   Client(client_id: Int, sub: ClientRoute)
/// }
/// ```
@internal
pub fn generate_type(node: Node) {
  case list.is_empty(node.children) {
    True -> Error(Nil)
    False -> {
      let sub_types =
        node.children
        |> list.filter_map(fn(node) { generate_type(node) })
        |> string.join("")

      let out = generate_type_just_this(node) <> sub_types

      Ok(out)
    }
  }
}

fn generate_type_just_this(node: Node) {
  let variants =
    node.children
    |> list.map(generate_type_variant)
    |> string.join("\n")

  let route_name = get_route_name(node.info)

  "pub type " <> route_name <> " {\n" <> variants <> "\n}" <> block_break
}

/// Generate
/// ```
///   User(user_id: Int, sub: UserRoute)
/// ```
fn generate_type_variant(node: Node) {
  let type_name = get_type_name(node.info)

  let sub = case list.is_empty(node.children) {
    True -> option.None
    False -> option.Some("sub: " <> get_route_name(node.info))
  }

  let params =
    node.info.segment_params
    |> list.filter_map(generate_type_variant_param)
    |> fn(items) {
      case sub {
        option.None -> items
        option.Some(sub) -> list.append(items, [sub])
      }
    }

  let params = case list.is_empty(params) {
    True -> ""
    False -> "(" <> string.join(params, ", ") <> ")"
  }

  "  " <> type_name <> params
}

fn generate_type_variant_param(param: types.Param) {
  case param.kind {
    types.ParamInt -> Ok(justin.snake_case(param.name) <> ": Int")
    types.ParamStr -> Ok(justin.snake_case(param.name) <> ": String")
  }
}

@internal
pub fn generate_segments_to_route(node: Node) {
  case list.is_empty(node.children) {
    True -> Error(Nil)
    False -> {
      let sub_types =
        list.filter_map(node.children, fn(sub) {
          generate_segments_to_route(sub)
        })
        |> string.join("")

      let out = generate_segments_to_route_just_this(node) <> sub_types

      Ok(out)
    }
  }
}

fn generate_segments_to_route_just_this(node: Node) {
  let segments_to_route_cases =
    node.children
    |> list.map(generate_segments_to_route_case)
    |> string.join("\n")

  let function_name =
    [get_function_name(node.info), "segments_to_route"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  let type_name = get_type_name(node.info)

  "pub fn "
  <> function_name
  <> "(segments: List(String)) -> Result("
  <> type_name
  <> "Route, Nil) {\n"
  <> "  case segments {\n"
  <> segments_to_route_cases
  <> "\n    _ -> Error(Nil)\n"
  <> "  }\n"
  <> "}"
  <> block_break
}

fn generate_segments_to_route_case(node: Node) {
  let matched_params =
    node.info.segments
    |> list.map(fn(param) {
      case param {
        types.Lit(val) -> "\"" <> val <> "\""
        types.Str(name) -> name
        types.Int(name) -> name
      }
    })
    |> string.join(", ")

  let matched_params = case list.is_empty(node.children) {
    True -> matched_params
    False -> matched_params <> ", ..rest"
  }

  let left = "[" <> matched_params <> "]"

  let match_right_inner =
    node.info.segments
    |> list.filter_map(fn(seg) {
      case seg {
        types.Lit(_) -> Error(Nil)
        types.Str(name) -> Ok(name)
        types.Int(name) -> Ok(name)
      }
    })
    |> fn(params) {
      case list.is_empty(node.children) {
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

  let right = case list.is_empty(node.children) {
    True -> {
      get_type_name(node.info) <> match_right_inner <> " |> Ok"
    }
    False -> {
      let fn_name = get_function_name(node.info) <> "_segments_to_route"

      fn_name <> "(rest) |> result.map(fn(sub) {
" <> get_type_name(node.info) <> match_right_inner <> "
        })"
    }
  }

  let right =
    list.fold(node.info.segments, right, fn(acc, segment) {
      case segment {
        types.Lit(_) -> acc
        types.Str(_) -> acc
        types.Int(name) -> {
          "with_int(" <> name <> ", fn(" <> name <> ") { " <> acc <> " })"
        }
      }
    })

  indent <> indent <> left <> " -> " <> right
}

@internal
pub fn generate_route_to_path(node: Node) {
  case list.is_empty(node.children) {
    True -> Error(Nil)
    False -> {
      let sub_types =
        list.filter_map(node.children, fn(node) { generate_route_to_path(node) })
        |> string.join("\n")

      { generate_route_to_path_just_this(node) <> sub_types } |> Ok
    }
  }
}

fn generate_route_to_path_just_this(node: Node) -> String {
  let route_to_path_cases =
    node.children
    |> list.map(generate_route_to_path_case)
    |> string.join("\n")

  let function_name =
    [get_function_name(node.info), "route_to_path"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  "pub fn "
  <> function_name
  <> "(route: "
  <> get_type_name(node.info)
  <> "Route) -> String {\n"
  <> indent
  <> "case route {\n"
  <> route_to_path_cases
  <> "\n  }\n"
  <> "}"
  <> block_break
}

fn generate_route_to_path_case(node: Node) {
  let variant_params =
    node.info.segments
    |> list.filter_map(fn(seg) {
      case seg {
        types.Lit(_) -> Error(Nil)
        types.Str(name) -> Ok(name)
        types.Int(name) -> Ok(name)
      }
    })
    |> fn(items) {
      case list.is_empty(node.children) {
        True -> items
        False -> list.append(items, ["sub"])
      }
    }

  let variant_params_str = case list.is_empty(variant_params) {
    True -> ""
    False -> "(" <> string.join(variant_params, ",") <> ")"
  }

  let path =
    node.info.segments
    |> list.map(fn(seg) {
      case seg {
        types.Lit(val) -> "\"" <> val <> "/\""
        types.Str(name) -> name
        types.Int(name) -> "int.to_string(" <> name <> ")"
      }
    })
    |> string.join(" <> ")

  let path = case list.is_empty(node.children) {
    True -> path
    False ->
      path <> " <> " <> get_function_name(node.info) <> "_route_to_path(sub)"
  }

  let path = case path {
    "" -> "\"/\""
    path -> "\"/\" <> " <> path
  }

  indent
  <> indent
  <> get_type_name(node.info)
  <> variant_params_str
  <> " -> "
  <> path
}

@internal
pub fn generate_helpers(node: Node) {
  // Only leaf nodes are generated
  case list.is_empty(node.children) {
    True -> {
      generate_helpers_just_this(node)
    }
    False -> {
      list.map(node.children, fn(node) { generate_helpers(node) })
      |> string.join("")
    }
  }
}

fn generate_helpers_just_this(node: Node) {
  generate_route_helper(node)
}

fn generate_route_helper(cont: Node) {
  let function_name = get_function_name(cont.info) <> "_route"

  let function_arguments =
    get_function_arguments([], cont.info)
    |> list.map(fn(param) {
      let type_ = case param.kind {
        types.ParamInt -> "Int"
        types.ParamStr -> "String"
      }

      justin.snake_case(param.name) <> ": " <> type_
    })
    |> string.join(", ")

  let body =
    "  "
    <> generate_route_helper_body([], cont.info)
    |> string.join("\n  |> ")

  "pub fn "
  <> function_name
  <> "("
  <> function_arguments
  <> ") -> Route {\n"
  <> body
  <> "\n"
  <> "}"
  <> block_break
}

@internal
pub fn get_function_arguments(
  acc: List(types.Param),
  info: Info,
) -> List(types.Param) {
  // First we want to namespace the given acc with this info
  let current_params =
    acc
    |> list.map(fn(param) {
      types.Param(..param, name: info.name <> "_" <> param.name)
    })

  let new_params =
    info.segment_params
    |> list.map(fn(param) {
      types.Param(..param, name: info.name <> "_" <> param.name)
    })

  let next_acc = list.append(new_params, current_params)

  case info.ancestor {
    option.None -> next_acc
    option.Some(ancestor) -> get_function_arguments(next_acc, ancestor)
  }
}

fn generate_route_helper_body(acc: List(String), info: Info) {
  let params =
    info.segment_params
    |> list.map(fn(param) { justin.snake_case(info.name <> "_" <> param.name) })
    |> fn(entries) {
      case list.is_empty(acc) {
        True -> entries
        False -> list.append(entries, ["_"])
      }
    }

  let params = case list.is_empty(params) {
    True -> ""
    False -> "(" <> string.join(params, ", ") <> ")"
  }

  let new_line = get_type_name(info) <> params

  let next_acc = list.append(acc, [new_line])

  case info.ancestor {
    option.None -> next_acc
    option.Some(ancestor) -> generate_route_helper_body(next_acc, ancestor)
  }
}

fn get_function_name(info: Info) -> String {
  get_function_name_do([], info)
  |> string.join("_")
}

fn get_function_name_do(collected: List(String), info: Info) {
  let next = list.prepend(collected, justin.snake_case(info.name))

  case info.ancestor {
    option.None -> next
    option.Some(ancestor) -> get_function_name_do(next, ancestor)
  }
}

fn get_type_name(info: Info) -> String {
  get_type_name_do([], info)
  |> string.join("")
}

fn get_type_name_do(collected: List(String), info: Info) {
  let next = list.prepend(collected, justin.pascal_case(info.name))

  case info.ancestor {
    option.None -> next
    option.Some(ancestor) -> get_type_name_do(next, ancestor)
  }
}

fn get_route_name(info: Info) -> String {
  get_type_name(info) <> "Route"
}

@internal
pub fn generate_utils() {
  "
fn with_int(str: String, fun) {
    int.parse(str)
    |> result.try(fun)
}
"
}
