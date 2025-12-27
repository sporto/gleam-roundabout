import glam/doc.{type Document}
import gleam/list
import gleam/option
import gleam/string
import roundabout/internal/common
import roundabout/internal/node.{
  type Info, type Node, type Segment, SegFixed, SegParam,
}
import roundabout/internal/parameter

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
pub fn generate_type_rec(ancestors: List(Info), node: Node) -> Document {
  case list.is_empty(node.children) {
    True -> doc.from_string("")
    False -> {
      let next_ancestors = list.prepend(ancestors, node.info)

      let sub_types =
        node.children
        |> list.map(fn(node) { generate_type_rec(next_ancestors, node) })

      let this = generate_type(ancestors, node)

      doc.concat(list.prepend(sub_types, this))
    }
  }
}

pub fn generate_type(ancestors: List(Info), node: Node) -> Document {
  let next_ancestors = list.prepend(ancestors, node.info)

  let variants =
    node.children
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
  let type_name = common.get_type_name(ancestors, node.info)

  let sub = case list.is_empty(node.children) {
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
    SegFixed(_) -> Error(Nil)
  }
}

fn get_route_name(ancestors: List(Info), info: Info) -> String {
  common.get_type_name(ancestors, info) <> "Route"
}
