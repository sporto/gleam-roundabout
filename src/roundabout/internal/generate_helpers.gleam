import glam/doc.{type Document}
import gleam/list
import gleam/string
import roundabout/internal/common.{pipe_join}
import roundabout/internal/node.{type Info, type Node, SegFixed, SegParam}
import roundabout/internal/parameter
import roundabout/internal/type_name

pub fn generate_helpers_rec(ancestors: List(Info), node: Node) -> Document {
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

  let function_arguments = common.get_function_arguments(ancestors, cont.info)

  let this_function_arguments =
    function_arguments
    |> list.map(parameter.print_name_and_type)
    |> string.join(", ")

  let body =
    generate_route_helper_body(ancestors, [], cont.info)
    |> doc.join(pipe_join())

  doc.concat([
    doc.from_string(
      "pub fn "
      <> function_name
      <> "("
      <> this_function_arguments
      <> ") -> Route {",
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

  let function_arguments = common.get_function_arguments(ancestors, cont.info)

  let this_function_arguments =
    function_arguments
    |> list.map(parameter.print_name_and_type)
    |> string.join(", ")

  let callee_arguments =
    function_arguments
    |> list.map(parameter.name)
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

pub fn generate_route_helper_body(
  ancestors: List(Info),
  acc: List(Document),
  info: Info,
) -> List(Document) {
  let ancestor_names =
    list.map(ancestors, fn(info) { type_name.snake(info.name) })

  let params =
    info.path
    |> list.filter_map(common.segment_to_param)
    |> list.map(parameter.qualified_name(
      ancestor_names,
      type_name.snake(info.name),
      _,
    ))
    |> fn(entries) {
      case list.length(acc) {
        0 | 1 -> entries
        _ -> {
          list.append(entries, ["_"])
        }
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
