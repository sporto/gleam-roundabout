import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import justin
import route_gen/types.{
  type Contribution, type ContributionInfo, type InputDef, Contribution,
  ContributionInfo,
}

@internal
pub fn generate_helpers(contributions: List(Contribution(types.Namespaced))) {
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

fn generate_helpers_for_contributions(
  contributions: List(Contribution(types.Namespaced)),
) {
  list.map(contributions, generate_helpers_for_contribution)
  |> string.join("")
}

fn generate_helpers_for_contribution(cont: Contribution(types.Namespaced)) {
  case list.is_empty(cont.children) {
    True -> {
      generate_route_helper(cont)
    }
    False -> ""
  }
  // "pub fn _path("
}

@internal
pub fn generate_route_helper(cont: Contribution(types.Namespaced)) {
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

  // full_path
  // |> list.flat_map(fn(cont) {
  //   cont.segment_params
  //   |> list.map(fn(param) {
  //     let type_ = case param.kind {
  //       types.ParamInt -> "Int"
  //       types.ParamStr -> "String"
  //     }

  //     justin.snake_case(cont.name <> "_" <> param.name) <> ": " <> type_
  //   })
  // })
  // |> string.join(", ")

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

@internal
pub fn add_namespace(
  namespace: String,
  items: List(Contribution(types.NotNamespaced)),
) -> List(Contribution(types.Namespaced)) {
  list.map(items, fn(item) {
    let info = item.info
    let snake_name = justin.snake_case(namespace) <> "_" <> info.name
    // let name = namespace <> info.name

    let info = ContributionInfo(..info, name: snake_name)

    let children = add_namespace(snake_name, item.children)

    Contribution(..item, info:, children:)
  })
}

@internal
pub fn get_function_arguments(
  acc: List(types.Param),
  info: ContributionInfo,
) -> List(types.Param) {
  // First we want to namespace the given acc with this info
  let current_params =
    acc
    |> list.map(fn(param) {
      types.Param(..param, name: info.name <> "_" <> param.name)
    })

  let new_params = info.segment_params

  let next_acc = list.append(new_params, current_params)

  // info.name

  case info.ancestor {
    option.None -> next_acc
    option.Some(ancestor) -> get_function_arguments(next_acc, ancestor)
  }
}

fn generate_route_helper_body(acc: List(String), info: ContributionInfo) {
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

  let new_line = justin.pascal_case(info.name) <> params

  let next_acc = list.append(acc, [new_line])

  case info.ancestor {
    option.None -> next_acc
    option.Some(ancestor) -> generate_route_helper_body(next_acc, ancestor)
  }
}
