import birdie
import glam/doc
import roundabout/internal/constant
import roundabout/internal/fixtures
import roundabout/internal/generate_route_to_path as subject
import roundabout/internal/node.{Info, Node}
import roundabout/internal/type_name

pub fn get_branch_result_root_empty_test() {
  assert subject.get_branch_result(
      True,
      [],
      Node(Info(type_name.unsafe("Home"), path: []), children: []),
    )
    |> doc.to_string(80)
    == "\"/\""
}

pub fn get_branch_result_not_root_empty_test() {
  assert subject.get_branch_result(
      False,
      [],
      Node(Info(type_name.unsafe("Dashboard"), path: []), children: []),
    )
    |> doc.to_string(80)
    == "\"\""
}

pub fn get_branch_result_root_with_path_test() {
  assert subject.get_branch_result(
      True,
      [],
      Node(
        Info(type_name.unsafe("Users"), path: [
          node.SegLit(constant.unsafe("users")),
        ]),
        children: [],
      ),
    )
    |> doc.to_string(80)
    == "\"/\" <> \"users\""
}

pub fn get_branch_result_root_with_sub_test() {
  assert subject.get_branch_result(
      True,
      [],
      Node(Info(type_name.unsafe("Users"), path: []), children: [
        Node(Info(type_name.unsafe("Show"), path: []), children: []),
      ]),
    )
    |> doc.to_string(80)
    == "\"/\" <> users_route_to_path(sub)"
}

pub fn generate_route_to_path_root_test() {
  let root = fixtures.fixture_root()

  let actual =
    subject.generate_route_to_path([], root)
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_route_to_path_root")
}

pub fn generate_route_to_path_rec_test() {
  let root = fixtures.fixture_root()

  let actual =
    subject.generate_route_to_path_rec([], root)
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_route_to_path_rec")
}
