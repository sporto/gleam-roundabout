import birdie
import gleam/option
import route_gen/generate
import route_gen/types

pub fn generate_route_helper_test() {
  let contribution =
    types.Contribution(
      children: [],
      info: types.ContributionInfo(
        ancestor: option.Some(
          types.ContributionInfo(
            ancestor: option.Some(
              types.ContributionInfo(
                ancestor: option.None,
                name: "Clients",
                segment_params: [
                  types.Param("id", types.ParamInt),
                ],
              ),
            ),
            name: "clients_orders",
            segment_params: [
              types.Param("id", types.ParamStr),
            ],
          ),
        ),
        name: "clients_orders_track",
        segment_params: [],
      ),
    )

  let actual = generate.generate_route_helper(contribution)

  actual
  |> birdie.snap(title: "route_helper")
}
