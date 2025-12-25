import glam/doc.{type Document}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import roundabout/constant
import roundabout/node.{type Info, type Node, type Segment, SegLit, SegParam}
import roundabout/parameter
import roundabout/type_name

/// Join two strings with <>
/// We allow breaking just before
fn string_join() {
  doc.flex_break(" ", "")
  |> doc.append(doc.from_string("<> "))
}

fn pipe_join() {
  doc.flex_break(" ", "")
  |> doc.append(doc.from_string("|> "))
}

fn case_arrow() {
  doc.from_string(" ->")
  |> doc.append(doc.flex_break(" ", ""))
}

@internal
pub fn generate_header() {
  "//// This module was generated using roundabout.
////
"
  |> doc.from_string
}

@internal
pub fn generate_imports() -> Document {
  [
    doc.from_string("import gleam/int"),
    doc.line,
    doc.from_string("import gleam/result"),
    doc.lines(2),
  ]
  |> doc.concat
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
pub fn generate_type_rec(ancestors: List(Info), node: Node) -> Document {
  case list.is_empty(node.sub) {
    True -> doc.from_string("")
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        node.sub
        |> list.map(fn(node) { generate_type_rec(next_ancestors, node) })

      let this = generate_type(ancestors, node)

      doc.concat(list.prepend(sub_types, this))
    }
  }
}

@internal
pub fn generate_type(ancestors: List(Info), node: Node) -> Document {
  let next_ancestors = list.prepend(ancestors, node.info)

  let variants =
    node.sub
    |> list.map(generate_type_variant(next_ancestors, _))
    |> doc.join(doc.line)

  let route_name = get_route_name(ancestors, node.info)

  doc.concat([
    doc.from_string("pub type " <> route_name <> " {"),
    doc.nest_docs(
      [
        doc.line,
        variants,
      ],
      2,
    ),
    doc.line,
    doc.from_string("}"),
    doc.lines(2),
  ])
}

/// Generate one type variant e.g.
///
/// ```
///   User(user_id: Int, sub: UserRoute)
/// ```
fn generate_type_variant(ancestors: List(Info), node: Node) -> Document {
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

  doc.from_string(type_name <> params)
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
pub fn generate_segments_to_route_rec(
  ancestors: List(Info),
  node: Node,
) -> Document {
  case list.is_empty(node.sub) {
    True -> doc.from_string("")
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        list.map(node.sub, fn(sub) {
          generate_segments_to_route_rec(next_ancestors, sub)
        })

      let this = generate_segments_to_route(ancestors, node)

      doc.concat(list.prepend(sub_types, this))
    }
  }
}

@internal
pub fn generate_segments_to_route(ancestors: List(Info), node: Node) -> Document {
  let next_ancestors = list.prepend(ancestors, node.info)

  let segments_to_route_cases =
    node.sub
    |> list.map(generate_segments_to_route_case(next_ancestors, _))
    |> doc.join(doc.line)
    |> doc.append(doc.line)
    |> doc.append(doc.from_string("_ -> Error(Nil)"))

  let function_name =
    [get_function_name(ancestors, node.info), "segments_to_route"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  let type_name = get_type_name(ancestors, node.info)

  let pub_prefix = case list.is_empty(ancestors) {
    True -> "pub "
    False -> ""
  }

  doc.concat([
    doc.from_string(
      pub_prefix
      <> "fn "
      <> function_name
      <> "(segments: List(String)) -> Result("
      <> type_name
      <> "Route, Nil) {",
    ),
    doc.nest_docs(
      [
        doc.line,
        doc.from_string("case segments {"),
        doc.nest_docs(
          [
            doc.line,
            segments_to_route_cases,
          ],
          2,
        ),
        doc.line,
        doc.from_string("}"),
      ],
      2,
    ),
    doc.line,
    doc.from_string("}"),
    doc.lines(2),
  ])
}

fn generate_segments_to_route_case(
  ancestors: List(Info),
  node: Node,
) -> Document {
  let matched_params =
    node.info.path
    |> list.map(fn(segment) {
      case segment {
        SegLit(value) -> doc.from_string("\"" <> constant.value(value) <> "\"")
        SegParam(param) -> doc.from_string(parameter.name(param))
      }
    })
    |> fn(self) {
      case list.is_empty(node.sub) {
        True -> self
        False -> list.append(self, [doc.from_string("..rest")])
      }
    }
    |> doc.join(doc.from_string(", "))

  let left =
    doc.concat([doc.from_string("["), matched_params, doc.from_string("]")])

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
      doc.from_string(get_type_name(ancestors, node.info) <> match_right_inner)
      |> doc.append(pipe_join())
      |> doc.append(doc.from_string("Ok"))
    }
    False -> {
      let fn_name =
        get_function_name(ancestors, node.info) <> "_segments_to_route"

      doc.concat([
        doc.from_string(fn_name <> "(rest)"),
        pipe_join(),
        doc.from_string("result.map(fn(sub) {"),
        doc.nest_docs(
          [
            doc.line,
            doc.from_string(
              get_type_name(ancestors, node.info) <> match_right_inner,
            ),
          ],
          2,
        ),
        doc.line,
        doc.from_string("})"),
      ])
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

              doc.concat([
                doc.from_string(
                  "with_int(" <> name <> ", fn(" <> name <> ") { ",
                ),
                doc.nest_docs(
                  [
                    doc.line,
                    acc,
                  ],
                  2,
                ),
                doc.line,
                doc.from_string(" })"),
              ])
            }
          }
        }
      }
    })

  left
  |> doc.append(case_arrow())
  |> doc.append(right)
  |> doc.nest(2)
}

@internal
pub fn generate_route_to_path_rec(ancestors: List(Info), node: Node) -> Document {
  case list.is_empty(node.sub) {
    True -> doc.from_string("")
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        list.map(node.sub, fn(node) {
          generate_route_to_path_rec(next_ancestors, node)
        })

      let this = generate_route_to_path(ancestors, node)

      doc.concat(list.prepend(sub_types, this))
    }
  }
}

@internal
pub fn generate_route_to_path(ancestors: List(Info), node: Node) -> Document {
  let next_ancestors = list.prepend(ancestors, node.info)

  let route_to_path_cases =
    node.sub
    |> list.map(generate_route_to_path_case(next_ancestors, _))
    |> doc.join(doc.line)

  let function_name =
    [get_function_name(ancestors, node.info), "route_to_path"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  let pub_prefix = case list.is_empty(ancestors) {
    True -> "pub "
    False -> ""
  }

  doc.concat([
    doc.from_string(
      pub_prefix
      <> "fn "
      <> function_name
      <> "(route: "
      <> get_type_name(ancestors, node.info)
      <> "Route) -> String {",
    ),
    doc.nest_docs(
      [
        doc.line,
        doc.from_string("case route {"),
        doc.nest_docs(
          [
            doc.line,
            route_to_path_cases,
          ],
          2,
        ),
        doc.line,
        doc.from_string("}"),
      ],
      2,
    ),
    doc.line,
    doc.from_string("}"),
    doc.lines(2),
  ])
}

fn generate_route_to_path_case(ancestors: List(Info), node: Node) -> Document {
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

  let forward_slash = doc.from_string("\"/\"")

  let path =
    forward_slash
    |> fn(self) {
      // If there are segments, add <>
      case list.is_empty(node.info.path) {
        True -> self
        False ->
          self
          |> doc.append(string_join())
      }
    }
    // Add the segments
    |> doc.append(
      list.map(node.info.path, fn(seg) {
        case seg {
          SegLit(value) -> {
            doc.from_string("\"" <> constant.value(value) <> "/\"")
          }
          SegParam(param) -> {
            let name = parameter.name(param)

            case parameter.kind(param) {
              parameter.Str -> doc.from_string(name)
              parameter.Int -> {
                doc.from_string("int.to_string(" <> name <> ")")
              }
            }
          }
        }
      })
      |> doc.join(string_join()),
    )
    // If there are children
    // Add <> some_route_to_path(sub)
    |> fn(self) {
      case list.is_empty(node.sub) {
        True -> self
        False ->
          self
          |> doc.append(string_join())
          |> doc.append(doc.from_string(
            get_function_name(ancestors, node.info) <> "_route_to_path(sub)",
          ))
      }
    }

  doc.from_string(get_type_name(ancestors, node.info) <> variant_params_str)
  |> doc.append(case_arrow())
  |> doc.append(path)
  |> doc.nest(2)
}

@internal
pub fn generate_helpers_rec(ancestors: List(Info), node: Node) -> Document {
  // Only leaf nodes are generated
  case list.is_empty(node.sub) {
    True -> {
      generate_helpers(ancestors, node)
    }
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      list.map(node.sub, fn(node) { generate_helpers_rec(next_ancestors, node) })
      |> doc.concat
    }
  }
}

/// helpers
///
fn generate_helpers(ancestors: List(Info), node: Node) -> Document {
  doc.concat([
    generate_route_helper(ancestors, node),
    generate_path_helper(ancestors, node),
  ])
}

fn generate_route_helper(ancestors: List(Info), cont: Node) -> Document {
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
    generate_route_helper_body(ancestors, [], cont.info)
    |> doc.join(pipe_join())

  doc.concat([
    doc.from_string(
      "pub fn " <> function_name <> "(" <> function_arguments <> ") -> Route {",
    ),
    doc.nest_docs([doc.line, body], 2),
    doc.line,
    doc.from_string("}"),
    doc.lines(2),
  ])
}

fn generate_path_helper(ancestors: List(Info), cont: Node) -> Document {
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
    doc.from_string(route_function_name <> "(" <> callee_arguments <> ")")
    |> doc.append(pipe_join())
    |> doc.append(doc.from_string("route_to_path"))

  doc.concat([
    doc.from_string(
      "pub fn "
      <> path_function_name
      <> "("
      <> this_function_arguments
      <> ") -> String {",
    ),
    doc.nest_docs([doc.line, body], 2),
    doc.line,
    doc.from_string("}"),
    doc.lines(2),
  ])
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
  acc: List(Document),
  info: Info,
) -> List(Document) {
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

  let new_line = doc.from_string(type_name <> params)

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

@internal
pub fn generate_utils() -> Document {
  "
fn with_int(str: String, fun) {
    int.parse(str)
    |> result.try(fun)
}
"
  |> doc.from_string
}
