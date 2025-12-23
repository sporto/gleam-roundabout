import gleam/list
import gleam/result
import gleam/set
import gleam/string
import justin
import route_gen/types.{
  type Contribution, type ContributionInfo, type InputDef, Contribution,
  ContributionInfo,
}

@internal
pub fn generate_helpers(contributions: List(Contribution)) {
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

fn generate_helpers_for_contributions(contributions: List(Contribution)) {
  list.map(contributions, generate_helpers_for_contribution)
  |> string.join("")
}

fn generate_helpers_for_contribution(cont: Contribution) {
  "pub fn _path("
  generate_route_helper(cont)
}

fn generate_route_helper(cont: Contribution) {
  let fn_name =
    cont.ancestors
    |> list.map(fn(a) { a.func_name })
    |> list.append([cont.info.func_name, "route"])
    |> string.join("_")

  let params = list.flat_map(cont.ancestors, fn(ancestor) { todo })

  "pub fn "
  <> fn_name
  <> "("
  // <> params
  <> ") {\n"
  //
  <> "todo\n"
  <> "}"
}
