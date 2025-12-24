import birdie
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
  |> birdie.snap(title: "generate_type")
}

pub fn generate_segments_to_route_test() {
  let assert Ok(root) = parse.parse(routes)

  let assert Ok(actual) = generate.generate_segments_to_route(root)

  actual
  |> birdie.snap(title: "generate_segments_to_route")
}

pub fn generate_route_to_path_test() {
  let assert Ok(root) = parse.parse(routes)

  let assert Ok(actual) = generate.generate_route_to_path(root)

  actual
  |> birdie.snap(title: "generate_route_to_path")
}

pub fn generate_helpers_test() {
  let assert Ok(root) = parse.parse(routes)

  let actual = generate.generate_helpers(root)

  actual
  |> birdie.snap(title: "generate_helpers")
}
