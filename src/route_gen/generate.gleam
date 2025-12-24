import gleam/list
import gleam/option
import gleam/string
import justin
import route_gen/types.{type Info, type Node}

const indent = "  "

const block_break = "\n\n"

@internal
pub fn generate_imports() {
  ["import gleam/int", "import gleam/result"]
  |> string.join("\n")
  <> block_break
}

/// Recursively generates route types like:
///
/// ```gleam
/// pub type Route {
///   Home
///   Client(client_id: Int, sub: ClientRoute)
/// }
///
/// put type ClientRoute {
///   ...
/// ```
///
@internal
pub fn generate_type_rec(ancestors: List(Info), node: Node) {
  case list.is_empty(node.children) {
    True -> Error(Nil)
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        node.children
        |> list.filter_map(fn(node) { generate_type_rec(next_ancestors, node) })
        |> string.join("")

      let out = generate_type(ancestors, node) <> sub_types

      Ok(out)
    }
  }
}

fn generate_type(ancestors: List(Info), node: Node) {
  let next_ancestors = list.prepend(ancestors, node.info)

  let variants =
    node.children
    |> list.map(generate_type_variant(next_ancestors, _))
    |> string.join("\n")

  let route_name = get_route_name(ancestors, node.info)

  "pub type " <> route_name <> " {\n" <> variants <> "\n}" <> block_break
}

/// Generate one type variant e.g.
///
/// ```
///   User(user_id: Int, sub: UserRoute)
/// ```
fn generate_type_variant(ancestors: List(Info), node: Node) {
  let type_name = get_type_name(ancestors, node.info)

  let sub = case list.is_empty(node.children) {
    True -> option.None
    False -> option.Some("sub: " <> get_route_name(ancestors, node.info))
  }

  let params =
    node.info.segments
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

fn generate_type_variant_param(segment: types.Segment) {
  case segment {
    types.Int(name) -> Ok(justin.snake_case(name) <> ": Int")
    types.Str(name) -> Ok(justin.snake_case(name) <> ": String")
    types.Lit(_) -> Error(Nil)
  }
}

/// Generates the segments to route functions
///
/// e.g.
/// ```
/// pub fn segments_to_route(segments: List(String)) {
///   case segments {
///     [] -> Home |> Ok
///     ...
///   }
/// }
/// ```
///
@internal
pub fn generate_segments_to_route_rec(ancestors: List(Info), node: Node) {
  case list.is_empty(node.children) {
    True -> Error(Nil)
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        list.filter_map(node.children, fn(sub) {
          generate_segments_to_route_rec(next_ancestors, sub)
        })
        |> string.join("")

      let out = generate_segments_to_route(ancestors, node) <> sub_types

      Ok(out)
    }
  }
}

fn generate_segments_to_route(ancestors: List(Info), node: Node) {
  let next_ancestors = list.prepend(ancestors, node.info)

  let segments_to_route_cases =
    node.children
    |> list.map(generate_segments_to_route_case(next_ancestors, _))
    |> string.join("\n")

  let function_name =
    [get_function_name(ancestors, node.info), "segments_to_route"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  let type_name = get_type_name(ancestors, node.info)

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

fn generate_segments_to_route_case(ancestors: List(Info), node: Node) {
  let matched_params =
    node.info.segments
    |> list.map(fn(segment) {
      case segment {
        types.Lit(name) -> "\"" <> justin.snake_case(name) <> "\""
        types.Str(name) -> justin.snake_case(name)
        types.Int(name) -> justin.snake_case(name)
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
        types.Str(name) -> Ok(justin.snake_case(name))
        types.Int(name) -> Ok(justin.snake_case(name))
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
      get_type_name(ancestors, node.info) <> match_right_inner <> " |> Ok"
    }
    False -> {
      let fn_name =
        get_function_name(ancestors, node.info) <> "_segments_to_route"

      fn_name <> "(rest) |> result.map(fn(sub) {
" <> get_type_name(ancestors, node.info) <> match_right_inner <> "
        })"
    }
  }

  let right =
    list.fold(node.info.segments, right, fn(acc, segment) {
      case segment {
        types.Lit(_) -> acc
        types.Str(_) -> acc
        types.Int(name) -> {
          "with_int("
          <> justin.snake_case(name)
          <> ", fn("
          <> justin.snake_case(name)
          <> ") { "
          <> acc
          <> " })"
        }
      }
    })

  indent <> indent <> left <> " -> " <> right
}

@internal
pub fn generate_route_to_path_rec(ancestors: List(Info), node: Node) {
  case list.is_empty(node.children) {
    True -> Error(Nil)
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        list.filter_map(node.children, fn(node) {
          generate_route_to_path_rec(next_ancestors, node)
        })
        |> string.join("\n")

      { generate_route_to_path(ancestors, node) <> sub_types } |> Ok
    }
  }
}

fn generate_route_to_path(ancestors: List(Info), node: Node) -> String {
  let next_ancestors = list.prepend(ancestors, node.info)

  let route_to_path_cases =
    node.children
    |> list.map(generate_route_to_path_case(next_ancestors, _))
    |> string.join("\n")

  let function_name =
    [get_function_name(ancestors, node.info), "route_to_path"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  "pub fn "
  <> function_name
  <> "(route: "
  <> get_type_name(ancestors, node.info)
  <> "Route) -> String {\n"
  <> indent
  <> "case route {\n"
  <> route_to_path_cases
  <> "\n  }\n"
  <> "}"
  <> block_break
}

fn generate_route_to_path_case(ancestors: List(Info), node: Node) {
  let variant_params =
    node.info.segments
    |> list.filter_map(fn(seg) {
      case seg {
        types.Lit(_) -> Error(Nil)
        types.Str(name) -> Ok(justin.snake_case(name))
        types.Int(name) -> Ok(justin.snake_case(name))
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
    False -> "(" <> string.join(variant_params, ", ") <> ")"
  }

  let path =
    node.info.segments
    |> list.map(fn(seg) {
      case seg {
        types.Lit(name) -> "\"" <> name <> "/\""
        types.Str(name) -> justin.snake_case(name)
        types.Int(name) -> "int.to_string(" <> justin.snake_case(name) <> ")"
      }
    })
    |> string.join(" <> ")

  let path = case list.is_empty(node.children) {
    True -> path
    False ->
      path
      <> " <> "
      <> get_function_name(ancestors, node.info)
      <> "_route_to_path(sub)"
  }

  let path = case path {
    "" -> "\"/\""
    path -> "\"/\" <> " <> path
  }

  indent
  <> indent
  <> get_type_name(ancestors, node.info)
  <> variant_params_str
  <> " -> "
  <> path
}

@internal
pub fn generate_helpers_rec(ancestors: List(Info), node: Node) {
  // Only leaf nodes are generated
  case list.is_empty(node.children) {
    True -> {
      generate_helpers(ancestors, node)
    }
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      list.map(node.children, fn(node) {
        generate_helpers_rec(next_ancestors, node)
      })
      |> string.join("")
    }
  }
}

fn generate_helpers(ancestors: List(Info), node: Node) {
  generate_route_helper(ancestors, node)
  <> generate_path_helper(ancestors, node)
}

fn generate_route_helper(ancestors: List(Info), cont: Node) {
  let function_name = get_function_name(ancestors, cont.info) <> "_route"

  let function_arguments =
    get_function_arguments(ancestors, [], cont.info)
    |> list.filter_map(fn(segment) {
      use type_name <- require_segment_type_name(segment)

      { justin.snake_case(segment.name) <> ": " <> type_name }
      |> Ok
    })
    |> string.join(", ")

  let body =
    "  "
    <> generate_route_helper_body(ancestors, [], cont.info)
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

fn generate_path_helper(ancestors: List(Info), cont: Node) {
  let function_name_prefix = get_function_name(ancestors, cont.info)
  let route_function_name = function_name_prefix <> "_route"
  let path_function_name = function_name_prefix <> "_path"

  let function_arguments = get_function_arguments(ancestors, [], cont.info)

  let this_function_arguments =
    function_arguments
    |> list.filter_map(fn(segment) {
      use type_name <- require_segment_type_name(segment)

      { justin.snake_case(segment.name) <> ": " <> type_name }
      |> Ok
    })
    |> string.join(", ")

  let callee_arguments =
    function_arguments
    |> list.map(fn(segment) { justin.snake_case(segment.name) })
    |> string.join(", ")

  let body =
    "  "
    <> route_function_name
    <> "("
    <> callee_arguments
    <> ")\n"
    <> "  |> route_to_path"

  "pub fn "
  <> path_function_name
  <> "("
  <> this_function_arguments
  <> ") -> String {\n"
  <> body
  <> "\n"
  <> "}"
  <> block_break
}

@internal
pub fn get_function_arguments(
  ancestors: List(Info),
  acc: List(types.Segment),
  info: Info,
) -> List(types.Segment) {
  // First we want to namespace the given acc with this info
  let current_segments =
    acc
    |> list.map(fn(segment) {
      let new_name = info.name <> "_" <> segment.name

      case segment {
        types.Lit(_) -> types.Lit(new_name)
        types.Str(_) -> types.Str(new_name)
        types.Int(_) -> types.Int(new_name)
      }
    })

  let new_segments =
    info.segments
    |> list.filter_map(fn(segment) {
      let new_name = info.name <> "_" <> segment.name

      case segment {
        types.Lit(_) -> Error(Nil)
        types.Str(_) -> Ok(types.Str(new_name))
        types.Int(_) -> Ok(types.Int(new_name))
      }
    })

  let next_acc = list.append(new_segments, current_segments)

  case ancestors {
    [next_ancestor, ..rest_ancestors] ->
      get_function_arguments(rest_ancestors, next_acc, next_ancestor)
    _ -> next_acc
  }
}

fn generate_route_helper_body(
  ancestors: List(Info),
  acc: List(String),
  info: Info,
) {
  let params =
    info.segments
    |> list.filter_map(fn(segment) {
      let name = justin.snake_case(info.name <> "_" <> segment.name)

      case segment {
        types.Lit(_) -> Error(Nil)
        types.Str(_) -> Ok(name)
        types.Int(_) -> Ok(name)
      }
    })
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

  let type_name = get_type_name(ancestors, info)

  let new_line = type_name <> params

  let next_acc = case type_name {
    "" -> acc
    _ -> list.append(acc, [new_line])
  }

  case ancestors {
    [next_ancestor, ..rest_ancestors] -> {
      generate_route_helper_body(rest_ancestors, next_acc, next_ancestor)
    }
    _ -> next_acc
  }
}

@internal
pub fn get_function_name(ancestors: List(Info), info: Info) -> String {
  get_function_name_do([], ancestors, info)
  |> list.filter(fn(seg) { seg != "" })
  |> string.join("_")
}

fn get_function_name_do(
  collected: List(String),
  ancestors: List(Info),
  info: Info,
) {
  let next = list.prepend(collected, justin.snake_case(info.name))

  case ancestors {
    [next_ancestor, ..rest_ancestors] -> {
      get_function_name_do(next, rest_ancestors, next_ancestor)
    }
    _ -> next
  }
}

@internal
pub fn get_type_name(ancestors: List(Info), info: Info) -> String {
  get_type_name_do([], ancestors, info)
  |> string.join("")
}

fn get_type_name_do(collected: List(String), ancestors: List(Info), info: Info) {
  let next = list.prepend(collected, justin.pascal_case(info.name))

  case ancestors {
    [next_ancestor, ..rest_ancestors] -> {
      get_type_name_do(next, rest_ancestors, next_ancestor)
    }
    _ -> next
  }
}

fn get_route_name(ancestors: List(Info), info: Info) -> String {
  get_type_name(ancestors, info) <> "Route"
}

fn get_segment_type_name(segment: types.Segment) {
  case segment {
    types.Int(_) -> Ok("Int")
    types.Str(_) -> Ok("String")
    types.Lit(_) -> Error(Nil)
  }
}

fn require_segment_type_name(segment: types.Segment, next) {
  case get_segment_type_name(segment) {
    Ok(type_name) -> next(type_name)
    Error(_) -> Error(Nil)
  }
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
