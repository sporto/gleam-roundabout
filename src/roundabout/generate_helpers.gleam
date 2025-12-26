import glam/doc.{type Document}
import gleam/list
import gleam/result
import gleam/string
import roundabout/common.{pipe_join}
import roundabout/node.{type Info, type Node, type Segment, SegLit, SegParam}
import roundabout/parameter
import roundabout/type_name

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
  let function_name = common.get_function_name(ancestors, cont.info) <> "_route"

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
  let function_name_prefix = common.get_function_name(ancestors, cont.info)
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

  let type_name = common.get_type_name(ancestors, info)

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
