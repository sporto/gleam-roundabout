import birdie
import route_gen.{Int, Lit, RouteDef}
import route_gen/generate
import route_gen/types

const routes = [
  RouteDef(name: "home", path: [], sub: []),
  RouteDef(name: "clients", path: [Lit("clients")], sub: []),
  RouteDef(
    name: "client",
    path: [Lit("clients"), Int("clientId")],
    sub: [
      RouteDef(name: "show", path: [], sub: []),
      RouteDef(
        name: "orders",
        path: [Lit("orders")],
        sub: [
          RouteDef(name: "index", path: [], sub: []),
          RouteDef(name: "show", path: [Int("orderId")], sub: []),
        ],
      ),
    ],
  ),
]

pub fn get_type_name_test() {
  let actual =
    generate.get_type_name(
      [types.Info(name: "client", segments: [])],
      types.Info(name: "simpleUser", segments: []),
    )

  assert actual == "ClientSimpleUser"
}

pub fn get_function_name_test() {
  let actual =
    generate.get_function_name(
      [types.Info(name: "client", segments: [])],
      types.Info(name: "simpleUser", segments: []),
    )

  assert actual == "client_simple_user"
}

pub fn generate_type_rec_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let assert Ok(actual) = generate.generate_type_rec([], root)

  actual
  |> birdie.snap(title: "generate_type_rec")
}

pub fn generate_segments_to_route_rec_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let assert Ok(actual) = generate.generate_segments_to_route_rec([], root)

  actual
  |> birdie.snap(title: "generate_segments_to_route_rec")
}

pub fn generate_route_to_path_rec_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let assert Ok(actual) = generate.generate_route_to_path_rec([], root)

  actual
  |> birdie.snap(title: "generate_route_to_path_rec")
}

pub fn generate_helpers_rec_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let actual = generate.generate_helpers_rec([], root)

  actual
  |> birdie.snap(title: "generate_helpers_rec")
}
