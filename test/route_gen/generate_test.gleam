import birdie
import gleam/result
import route_gen/generate
import route_gen/parameter
import route_gen/types.{Info, Node, SegLit, SegParam}

fn root() {
  use par_client_id <- result.try(parameter.new("clientId", parameter.Int))
  use par_order_id <- result.try(parameter.new("orderId", parameter.Int))

  Node(Info("", []), [
    Node(Info("home", []), []),
    Node(Info("clients", [SegLit("clients")]), []),
    Node(Info("client", [SegLit("clients"), SegParam(par_client_id)]), [
      Node(Info("show", []), []),
      Node(Info("orders", [SegLit("orders")]), [
        Node(Info("index", []), []),
        Node(Info("show", [SegParam(par_order_id)]), []),
      ]),
    ]),
  ])
  |> Ok
}

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
  let assert Ok(root) = root()
  let actual = generate.generate_type([], root)

  actual
  |> birdie.snap(title: "generate_type_root")
}

pub fn generate_type_child_test() {
  let ancestors = [Info(name: "client", path: [])]

  let assert Ok(par_id) = parameter.new("id", parameter.Int)

  let node =
    Node(info: Info(name: "user", path: []), sub: [
      Node(info: Info(name: "Show", path: [SegParam(par_id)]), sub: []),
    ])

  let actual = generate.generate_type(ancestors, node)

  actual
  |> birdie.snap(title: "generate_type_child")
}

pub fn generate_type_rec_test() {
  let assert Ok(root) = root()
  let assert Ok(actual) = generate.generate_type_rec([], root)

  actual
  |> birdie.snap(title: "generate_type_rec")
}

/// generate_segments_to_route
///
pub fn generate_segments_to_route_root_test() {
  let assert Ok(root) = root()
  let actual = generate.generate_segments_to_route([], root)

  actual
  |> birdie.snap(title: "generate_segments_to_route_root")
}

pub fn generate_segments_to_route_rec_test() {
  let assert Ok(root) = root()
  let assert Ok(actual) = generate.generate_segments_to_route_rec([], root)

  actual
  |> birdie.snap(title: "generate_segments_to_route_rec")
}

/// generate_route_to_path
///
pub fn generate_route_to_path_root_test() {
  let assert Ok(root) = root()
  let actual = generate.generate_route_to_path([], root)

  actual
  |> birdie.snap(title: "generate_route_to_path_root")
}

pub fn generate_route_to_path_rec_test() {
  let assert Ok(root) = root()
  let assert Ok(actual) = generate.generate_route_to_path_rec([], root)

  actual
  |> birdie.snap(title: "generate_route_to_path_rec")
}

pub fn generate_helpers_rec_test() {
  let assert Ok(root) = root()
  let actual = generate.generate_helpers_rec([], root)

  actual
  |> birdie.snap(title: "generate_helpers_rec")
}
