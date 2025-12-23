import gleam/list
import gleam/result
import gleam/set
import justin
import route_gen/types.{
  type Contribution, type ContributionInfo, type InputDef, Contribution,
  ContributionInfo,
}

@internal
pub fn prepare_contributions(
  ancestors: List(ContributionInfo),
  definitions: List(InputDef),
) -> Result(List(Contribution), String) {
  use contributions <- result.try(
    list.try_map(definitions, prepare_contribution(ancestors, _)),
  )

  use contributions <- result.try(assert_no_duplicate_variant_names(
    contributions,
  ))

  Ok(contributions)
}

fn assert_no_duplicate_variant_names(contributions: List(Contribution)) {
  let variant_names = list.map(contributions, fn(item) { item.info.type_name })

  let as_set = set.from_list(variant_names)

  case list.length(variant_names) == set.size(as_set) {
    True -> Ok(contributions)
    False -> Error("Routes contain duplicate names")
  }
}

fn prepare_contribution(ancestors: List(ContributionInfo), definition: InputDef) {
  let type_name = justin.pascal_case(definition.name)
  let func_name = justin.snake_case(definition.name)

  let info = ContributionInfo(type_name:, func_name:)

  let children_ancestors = list.append(ancestors, [info])

  use children <- result.try(prepare_contributions(
    children_ancestors,
    definition.sub,
  ))

  Contribution(ancestors:, info:, children:) |> Ok
}
