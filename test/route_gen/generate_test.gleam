import birdie
import route_gen.{Int, Lit, Route}
import route_gen/generate
import route_gen/types.{Info, Node, SegInt}

const routes = [
  Route(name: "home", path: [], sub: []),
  Route(name: "clients", path: [Lit("clients")], sub: []),
  Route(
    name: "client",
    path: [Lit("clients"), Int("clientId")],
    sub: [
      Route(name: "show", path: [], sub: []),
      Route(
        name: "orders",
        path: [Lit("orders")],
        sub: [
          Route(name: "index", path: [], sub: []),
          Route(name: "show", path: [Int("orderId")], sub: []),
        ],
      ),
    ],
  ),
]

const routes2 = [Node(info: Info(name: "name", path: []), sub: [])]

pub fn get_type_name_test() {
  let actual =
    generate.get_type_name(
      [Info(name: "client", path: [])],
      Info(name: "simpleUser", path: []),
    )

  assert actual == "ClientSimpleUser"
}

pub fn get_function_name_test() {
  let actual =
    generate.get_function_name(
      [Info(name: "client", path: [])],
      Info(name: "simpleUser", path: []),
    )

  assert actual == "client_simple_user"
}

/// generate_type
///
pub fn generate_type_root_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let actual = generate.generate_type([], root)

  actual
  |> birdie.snap(title: "generate_type_root")
}

pub fn generate_type_child_test() {
  let ancestors = [Info(name: "client", path: [])]

  let node =
    Node(info: Info(name: "user", path: []), sub: [
      Node(info: Info(name: "Show", path: [SegInt("id")]), sub: []),
    ])

  let actual = generate.generate_type(ancestors, node)

  actual
  |> birdie.snap(title: "generate_type_child")
}

pub fn generate_type_rec_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let assert Ok(actual) = generate.generate_type_rec([], root)

  actual
  |> birdie.snap(title: "generate_type_rec")
}

/// generate_segments_to_route
///
pub fn generate_segments_to_route_root_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let actual = generate.generate_segments_to_route([], root)

  actual
  |> birdie.snap(title: "generate_segments_to_route_root")
}

pub fn generate_segments_to_route_rec_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let assert Ok(actual) = generate.generate_segments_to_route_rec([], root)

  actual
  |> birdie.snap(title: "generate_segments_to_route_rec")
}

/// generate_route_to_path
///
pub fn generate_route_to_path_root_test() {
  let assert Ok(root) = route_gen.parse(routes)

  let actual = generate.generate_route_to_path([], root)

  actual
  |> birdie.snap(title: "generate_route_to_path_root")
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
