import birdie
import gleam/option
import gleam/result
import route_gen/generate
import route_gen/parse
import route_gen/types

const routes = [
  types.InputDef(name: "home", path: [], sub: []),
  types.InputDef(name: "clients", path: [types.Lit("clients")], sub: []),
  types.InputDef(
    name: "client",
    path: [types.Lit("clients"), types.Int("clientId")],
    sub: [
      types.InputDef(name: "show", path: [], sub: []),
      types.InputDef(
        name: "orders",
        path: [types.Lit("orders")],
        sub: [
          types.InputDef(name: "index", path: [], sub: []),
          types.InputDef(name: "show", path: [types.Int("orderId")], sub: []),
        ],
      ),
    ],
  ),
]

pub fn generate_type_test() {
  let assert Ok(root) = parse.parse(routes)

  let assert Ok(actual) = generate.generate_type(root)

  actual
  |> birdie.snap(title: "type")
}

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
            name: "orders",
            segment_params: [
              types.Param("id", types.ParamStr),
            ],
          ),
        ),
        name: "track",
        segment_params: [],
      ),
    )

  let actual = generate.generate_route_helper(contribution)

  actual
  |> birdie.snap(title: "route_helper")
}
