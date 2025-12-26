import birdie
import glam/doc
import roundabout/constant
import roundabout/generate_helpers
import roundabout/generate_other
import roundabout/generate_route_to_path
import roundabout/generate_segments_to_route
import roundabout/generate_types
import roundabout/node.{Info, Node, SegLit, SegParam}
import roundabout/parameter
import roundabout/type_name

fn root() {
  Node(Info(type_name.unsafe(""), []), [
    Node(Info(type_name.unsafe("Home"), []), []),
    Node(
      Info(type_name.unsafe("Orders"), [SegLit(constant.unsafe("orders"))]),
      [],
    ),
    Node(
      Info(type_name.unsafe("User"), [
        SegLit(constant.unsafe("users")),
        SegParam(parameter.unsafe_int("user_id")),
      ]),
      [
        Node(Info(type_name.unsafe("Show"), []), []),
        Node(
          Info(type_name.unsafe("Delete"), [SegLit(constant.unsafe("delete"))]),
          [],
        ),
      ],
    ),
  ])
  |> Ok
}

pub fn generate_imports_test() {
  let actual = generate_other.generate_imports()

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_imports")
}

/// generate_type
///
pub fn generate_type_root_test() {
  let assert Ok(root) = root()
  let actual = generate_types.generate_type([], root)

  actual
  |> doc.to_string(80)
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

  let actual = generate_types.generate_type(ancestors, node)

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_type_child")
}

pub fn generate_type_rec_test() {
  let assert Ok(root) = root()
  let actual = generate_types.generate_type_rec([], root)

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_type_rec")
}

/// generate_segments_to_route
///
pub fn generate_segments_to_route_root_test() {
  let assert Ok(root) = root()
  let actual = generate_segments_to_route.generate_segments_to_route([], root)

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_segments_to_route_root")
}

pub fn generate_segments_to_route_rec_test() {
  let assert Ok(root) = root()

  let actual =
    generate_segments_to_route.generate_segments_to_route_rec([], root)
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_segments_to_route_rec")
}

/// generate_route_to_path
///
pub fn generate_route_to_path_root_test() {
  let assert Ok(root) = root()

  let actual =
    generate_route_to_path.generate_route_to_path([], root)
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_route_to_path_root")
}

pub fn generate_route_to_path_rec_test() {
  let assert Ok(root) = root()

  let actual =
    generate_route_to_path.generate_route_to_path_rec([], root)
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_route_to_path_rec")
}

pub fn generate_helpers_rec_test() {
  let assert Ok(root) = root()

  let actual =
    generate_helpers.generate_helpers_rec([], root)
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_helpers_rec")
}
