import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import justin
import route_gen/types.{type Info, type InputDef, type Node, Info, Node}

@internal
pub fn generate_imports() {
  ["import gleam/int", "import gleam/result"]
  |> string.join("\n")
  <> "\n\n"
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
        |> string.join("\n")

      let variants =
        node.children
        |> list.map(generate_type_variant)
        |> string.join("\n")

      let route_name = get_route_name(node.info)

      let this = "pub type " <> route_name <> " {\n" <> variants <> "\n}\n\n"

      let out = this <> sub_types

      Ok(out)
    }
  }
}

/// Generate
/// User(user_id: Int, sub: UserRoute)
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
pub fn generate_helpers(contributions: List(Node)) {
  // Only leaf should be generated
  case list.is_empty(contributions) {
    True -> Error(Nil)
    False -> {
      let sub_types =
        list.filter_map(contributions, fn(contribution) {
          generate_helpers(contribution.children)
        })
        |> string.join("\n")

      let out =
        generate_helpers_for_contributions(contributions) <> "\n\n" <> sub_types

      Ok(out)
    }
  }
}

fn generate_helpers_for_contributions(contributions: List(Node)) {
  list.map(contributions, generate_helpers_for_contribution)
  |> string.join("")
}

fn generate_helpers_for_contribution(cont: Node) {
  case list.is_empty(cont.children) {
    True -> {
      generate_route_helper(cont)
    }
    False -> ""
  }
  // "pub fn _path("
}

@internal
pub fn generate_route_helper(cont: Node) {
  // let full_path = list.append(cont.ancestors, [cont.info])

  let function_name = justin.snake_case(cont.info.name) <> "_route"

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
  <> "}\n\n"
}

// @internal
// pub fn add_namespace(
//   namespace: String,
//   items: List(Node),
// ) -> List(Node) {
//   list.map(items, fn(item) {
//     let info = item.info
//     let snake_name = justin.snake_case(namespace) <> "_" <> info.name
//     // let name = namespace <> info.name

//     let info = Info(..info, name: snake_name)

//     let children = add_namespace(snake_name, item.children)

//     Node(..item, info:, children:)
//   })
// }

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
