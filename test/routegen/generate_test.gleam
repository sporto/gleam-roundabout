import birdie
import routegen/constant
import routegen/generate
import routegen/node.{Info, Node, SegLit, SegParam}
import routegen/parameter
import routegen/type_name

fn root() {
  Node(Info(type_name.unsafe(""), []), [
    Node(Info(type_name.unsafe("Home"), []), []),
    Node(
      Info(type_name.unsafe("Clients"), [SegLit(constant.unsafe("clients"))]),
      [],
    ),
    Node(
      Info(type_name.unsafe("Client"), [
        SegLit(constant.unsafe("clients")),
        SegParam(parameter.unsafe_int("client_id")),
      ]),
      [
        Node(Info(type_name.unsafe("Show"), []), []),
        Node(
          Info(type_name.unsafe("Orders"), [SegLit(constant.unsafe("orders"))]),
          [
            Node(Info(type_name.unsafe("Index"), []), []),
            Node(
              Info(type_name.unsafe("Show"), [
                SegParam(parameter.unsafe_int("order_id")),
              ]),
              [],
            ),
          ],
        ),
      ],
    ),
  ])
  |> Ok
}

pub fn get_type_name_test() {
  let actual =
    generate.get_type_name(
      [Info(name: type_name.unsafe("Client"), path: [])],
      Info(name: type_name.unsafe("SimpleUser"), path: []),
    )

  assert actual == "ClientSimpleUser"
}

pub fn get_function_name_test() {
  let actual =
    generate.get_function_name(
      [Info(name: type_name.unsafe("Client"), path: [])],
      Info(name: type_name.unsafe("SimpleUser"), path: []),
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
  let ancestors = [Info(name: type_name.unsafe("Client"), path: [])]

  let assert Ok(par_id) = parameter.new("id", parameter.Int)

  let node =
    Node(info: Info(name: type_name.unsafe("User"), path: []), sub: [
      Node(
        info: Info(name: type_name.unsafe("Show"), path: [SegParam(par_id)]),
        sub: [],
      ),
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
