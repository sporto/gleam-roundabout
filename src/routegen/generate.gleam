import gleam/list
import gleam/option
import gleam/result
import gleam/string
import justin
import routegen/constant
import routegen/node.{type Info, type Node, type Segment, SegLit, SegParam}
import routegen/parameter
import routegen/type_name

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
  case list.is_empty(node.sub) {
    True -> Error(Nil)
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        node.sub
        |> list.filter_map(fn(node) { generate_type_rec(next_ancestors, node) })
        |> string.join("")

      let out = generate_type(ancestors, node) <> sub_types

      Ok(out)
    }
  }
}

@internal
pub fn generate_type(ancestors: List(Info), node: Node) {
  let next_ancestors = list.prepend(ancestors, node.info)

  let variants =
    node.sub
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

  let sub = case list.is_empty(node.sub) {
    True -> option.None
    False -> option.Some("sub: " <> get_route_name(ancestors, node.info))
  }

  let params =
    node.info.path
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

fn generate_type_variant_param(segment: Segment) {
  case segment {
    SegParam(param) -> Ok(parameter.full(param))
    SegLit(_) -> Error(Nil)
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
  case list.is_empty(node.sub) {
    True -> Error(Nil)
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        list.filter_map(node.sub, fn(sub) {
          generate_segments_to_route_rec(next_ancestors, sub)
        })
        |> string.join("")

      let out = generate_segments_to_route(ancestors, node) <> sub_types

      Ok(out)
    }
  }
}

@internal
pub fn generate_segments_to_route(ancestors: List(Info), node: Node) {
  let next_ancestors = list.prepend(ancestors, node.info)

  let segments_to_route_cases =
    node.sub
    |> list.map(generate_segments_to_route_case(next_ancestors, _))
    |> string.join("\n")

  let function_name =
    [get_function_name(ancestors, node.info), "segments_to_route"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  let type_name = get_type_name(ancestors, node.info)

  let pub_prefix = case list.is_empty(ancestors) {
    True -> "pub "
    False -> ""
  }

  pub_prefix
  <> "fn "
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
    node.info.path
    |> list.map(fn(segment) {
      case segment {
        SegLit(value) -> "\"" <> constant.value(value) <> "\""
        SegParam(param) -> parameter.name(param)
      }
    })
    |> string.join(", ")

  let matched_params = case list.is_empty(node.sub) {
    True -> matched_params
    False -> matched_params <> ", ..rest"
  }

  let left = "[" <> matched_params <> "]"

  let match_right_inner =
    node.info.path
    |> list.filter_map(fn(seg) {
      case seg {
        SegLit(_) -> Error(Nil)
        SegParam(param) -> Ok(parameter.name(param))
      }
    })
    |> fn(params) {
      case list.is_empty(node.sub) {
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

  let right = case list.is_empty(node.sub) {
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
    list.fold(node.info.path, right, fn(acc, segment) {
      case segment {
        SegLit(_) -> acc
        SegParam(param) -> {
          case parameter.kind(param) {
            parameter.Str -> acc
            parameter.Int -> {
              let name = parameter.name(param)

              "with_int(" <> name <> ", fn(" <> name <> ") { " <> acc <> " })"
            }
          }
        }
      }
    })

  indent <> indent <> left <> " -> " <> right
}

@internal
pub fn generate_route_to_path_rec(ancestors: List(Info), node: Node) {
  case list.is_empty(node.sub) {
    True -> Error(Nil)
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        list.filter_map(node.sub, fn(node) {
          generate_route_to_path_rec(next_ancestors, node)
        })
        |> string.join("\n")

      { generate_route_to_path(ancestors, node) <> sub_types } |> Ok
    }
  }
}

@internal
pub fn generate_route_to_path(ancestors: List(Info), node: Node) -> String {
  let next_ancestors = list.prepend(ancestors, node.info)

  let route_to_path_cases =
    node.sub
    |> list.map(generate_route_to_path_case(next_ancestors, _))
    |> string.join("\n")

  let function_name =
    [get_function_name(ancestors, node.info), "route_to_path"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  let pub_prefix = case list.is_empty(ancestors) {
    True -> "pub "
    False -> ""
  }

  pub_prefix
  <> "fn "
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
    node.info.path
    |> list.filter_map(fn(seg) {
      case seg {
        SegLit(_) -> Error(Nil)
        SegParam(param) -> {
          param
          |> parameter.name
          |> Ok
        }
      }
    })
    |> fn(items) {
      case list.is_empty(node.sub) {
        True -> items
        False -> list.append(items, ["sub"])
      }
    }

  let variant_params_str = case list.is_empty(variant_params) {
    True -> ""
    False -> "(" <> string.join(variant_params, ", ") <> ")"
  }

  let path =
    node.info.path
    |> list.map(fn(seg) {
      case seg {
        SegLit(value) -> "\"" <> constant.value(value) <> "/\""
        SegParam(param) -> {
          let name = parameter.name(param)

          case parameter.kind(param) {
            parameter.Str -> name
            parameter.Int -> "int.to_string(" <> name <> ")"
          }
        }
      }
    })
    |> string.join(" <> ")

  let path = case list.is_empty(node.sub) {
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
  case list.is_empty(node.sub) {
    True -> {
      generate_helpers(ancestors, node)
    }
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      list.map(node.sub, fn(node) { generate_helpers_rec(next_ancestors, node) })
      |> string.join("")
    }
  }
}

/// helpers
///
fn generate_helpers(ancestors: List(Info), node: Node) {
  generate_route_helper(ancestors, node)
  <> generate_path_helper(ancestors, node)
}

fn generate_route_helper(ancestors: List(Info), cont: Node) {
  let function_name = get_function_name(ancestors, cont.info) <> "_route"

  let function_arguments =
    get_function_arguments(ancestors, [], cont.info)
    |> list.filter_map(fn(segment) {
      case segment {
        SegLit(_) -> Error(Nil)
        SegParam(param) -> parameter.full(param) |> Ok
      }
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
      case segment {
        SegLit(_) -> Error(Nil)
        SegParam(name) -> parameter.full(name) |> Ok
      }
    })
    |> string.join(", ")

  let callee_arguments =
    function_arguments
    |> list.filter_map(fn(segment) {
      case segment {
        SegLit(_) -> Error(Nil)
        SegParam(name) -> Ok(parameter.name(name))
      }
    })
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
  acc: List(Segment),
  info: Info,
) -> List(Segment) {
  // First we want to namespace the given acc with this info
  let current_segments =
    acc
    |> list.filter_map(fn(segment) {
      case segment {
        SegLit(_) -> {
          Error("")
        }
        SegParam(param) -> {
          let new_name =
            type_name.snake(info.name) <> "_" <> parameter.name(param)

          use new_param <- result.try(parameter.new(
            new_name,
            parameter.kind(param),
          ))

          SegParam(new_param) |> Ok
        }
      }
    })

  let new_segments =
    info.path
    |> list.filter_map(fn(segment) {
      case segment {
        SegLit(_) -> Error(Nil)
        SegParam(param) -> {
          let new_name = {
            type_name.snake(info.name) <> "_" <> parameter.name(param)
          }

          use new_param <- result.try(
            parameter.new(new_name, parameter.kind(param))
            |> result.replace_error(Nil),
          )

          Ok(SegParam(new_param))
        }
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
    info.path
    |> list.filter_map(fn(segment) {
      case segment {
        SegLit(_) -> Error(Nil)
        SegParam(param) -> {
          { type_name.snake(info.name) <> "_" <> parameter.name(param) }
          |> Ok
        }
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
  let next = list.prepend(collected, type_name.snake(info.name))

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
  let next = list.prepend(collected, type_name.name(info.name))

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

fn get_segment_type_name(segment: Segment) {
  case segment {
    SegLit(_) -> Error(Nil)
    SegParam(param) -> parameter.type_name(param) |> Ok
  }
}

fn require_segment_type_name(segment: Segment, next) {
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
