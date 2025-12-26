import glam/doc.{type Document}
import gleam/list
import gleam/string
import roundabout/common
import roundabout/constant
import roundabout/node.{type Info, type Node, SegLit, SegParam}
import roundabout/parameter

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
  let is_root = list.is_empty(ancestors)
  let next_ancestors = list.prepend(ancestors, node.info)

  let route_to_path_cases =
    node.sub
    |> list.map(generate_route_to_path_case(is_root, next_ancestors, _))
    |> doc.join(doc.line)

  let function_name =
    [common.get_function_name(ancestors, node.info), "route_to_path"]
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
      <> common.get_type_name(ancestors, node.info)
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

fn generate_route_to_path_case(
  is_root: Bool,
  ancestors: List(Info),
  node: Node,
) -> Document {
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

  let branch_result = get_branch_result(is_root, ancestors, node)

  doc.from_string(
    common.get_type_name(ancestors, node.info) <> variant_params_str,
  )
  |> doc.append(common.case_arrow())
  |> doc.append(branch_result)
  |> doc.nest(2)
}

@internal
pub fn get_branch_result(
  is_root: Bool,
  ancestors: List(Info),
  node: Node,
) -> Document {
  let has_segments = !list.is_empty(node.info.path)

  let segments =
    list.map(node.info.path, fn(seg) {
      case seg {
        SegLit(value) -> {
          doc.from_string(
            common.double_quote <> constant.value(value) <> common.double_quote,
          )
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
    |> doc.join(
      common.string_join()
      |> doc.append(doc.from_string(common.forward_slash))
      |> doc.append(common.string_join()),
    )

  doc.empty
  |> fn(self) {
    case is_root || has_segments {
      True ->
        self
        |> doc.append(doc.from_string(common.forward_slash))
      False ->
        self
        |> doc.append(doc.from_string(
          common.double_quote <> common.double_quote,
        ))
    }
  }
  // Add the segments
  |> fn(self) {
    case has_segments {
      True ->
        self
        |> doc.append(common.string_join())
        |> doc.append(segments)
      False -> self
    }
  }
  // If there are children
  // Add `<> some_route_to_path(sub)`
  |> fn(self) {
    case list.is_empty(node.sub) {
      True -> self
      False ->
        self
        |> doc.append(common.string_join())
        |> doc.append(doc.from_string(
          common.get_function_name(ancestors, node.info)
          <> "_route_to_path(sub)",
        ))
    }
  }
}
