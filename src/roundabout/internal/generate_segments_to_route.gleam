import glam/doc.{type Document}
import gleam/list
import gleam/string
import roundabout/internal/ancestors.{type Ancestors}
import roundabout/internal/common.{case_arrow, double_quote, pipe_join}
import roundabout/internal/fixed
import roundabout/internal/node.{type Info, type Node, SegFixed, SegParam}
import roundabout/internal/parameter

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
pub fn generate_segments_to_route_rec(
  ancestors: Ancestors(Info),
  node: Node,
) -> Document {
  case list.is_empty(node.children) {
    True -> doc.from_string("")
    False -> {
      let next_ancestors = ancestors.push(ancestors, node.info)

      let sub_types =
        list.map(node.children, fn(sub) {
          generate_segments_to_route_rec(next_ancestors, sub)
        })

      let this = generate_segments_to_route(ancestors, node)

      doc.concat(list.prepend(sub_types, this))
    }
  }
}

pub fn generate_segments_to_route(
  ancestors: Ancestors(Info),
  node: Node,
) -> Document {
  let next_ancestors = ancestors.push(ancestors, node.info)

  let segments_to_route_cases =
    node.children
    |> list.map(generate_segments_to_route_case(next_ancestors, _))
    |> doc.join(doc.line)
    |> doc.append(doc.line)
    |> doc.append(doc.from_string("_ -> Error(Nil)"))

  let function_name =
    [common.generate_function_name(ancestors, node.info), "segments_to_route"]
    |> list.filter(fn(name) { !string.is_empty(name) })
    |> string.join("_")

  let type_name = common.get_type_name(ancestors, node.info)

  let pub_prefix = case ancestors.is_empty(ancestors) {
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
  ancestors: Ancestors(Info),
  node: Node,
) -> Document {
  let matched_params =
    node.info.path
    |> list.map(fn(segment) {
      case segment {
        SegFixed(value) ->
          doc.from_string(double_quote <> fixed.value(value) <> double_quote)
        SegParam(param) -> doc.from_string(parameter.print_name(param))
      }
    })
    |> fn(self) {
      case list.is_empty(node.children) {
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
        SegFixed(_) -> Error(Nil)
        SegParam(param) -> Ok(parameter.print_name(param))
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
      doc.from_string(
        common.get_type_name(ancestors, node.info) <> match_right_inner,
      )
      |> doc.append(pipe_join())
      |> doc.append(doc.from_string("Ok"))
    }
    False -> {
      let fn_name =
        common.generate_function_name(ancestors, node.info)
        <> "_segments_to_route"

      doc.concat([
        doc.from_string(fn_name <> "(rest)"),
        pipe_join(),
        doc.from_string("result.map(fn(sub) {"),
        doc.nest_docs(
          [
            doc.line,
            doc.from_string(
              common.get_type_name(ancestors, node.info) <> match_right_inner,
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
        SegFixed(_) -> acc
        SegParam(param) -> {
          case parameter.kind(param) {
            parameter.Str -> acc
            parameter.Int -> {
              let name = parameter.print_name(param)

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
