import birdie
import glam/doc
import roundabout/internal/ancestors
import roundabout/internal/common
import roundabout/internal/fixtures
import roundabout/internal/generate_helpers
import roundabout/internal/node
import roundabout/internal/parameter
import roundabout/internal/name

pub fn generate_route_helper_body_test() {
  // Given not ancestors
  let actual =
    generate_helpers.generate_route_helper_body(
      ancestors.empty(),
      [],
      node.Info(name.unsafe("User"), path: []),
    )
    |> doc.join(common.pipe_join())
    |> doc.to_string(80)

  assert actual == "User"
}

pub fn generate_route_helper_body_params_test() {
  let actual =
    generate_helpers.generate_route_helper_body(
      ancestors.empty(),
      [],
      node.Info(name.unsafe("User"), path: [
        node.SegParam(parameter.unsafe_int("id")),
      ]),
    )
    |> doc.join(common.pipe_join())
    |> doc.to_string(80)

  assert actual == "User(user_id)"
}

pub fn generate_route_helper_body_multiple_params_test() {
  let actual =
    generate_helpers.generate_route_helper_body(
      ancestors.empty(),
      [],
      node.Info(name.unsafe("User"), path: [
        node.SegParam(parameter.unsafe_int("id")),
        node.SegParam(parameter.unsafe_str("state")),
      ]),
    )
    |> doc.join(common.pipe_join())
    |> doc.to_string(80)

  assert actual == "User(user_id, user_state)"
}

pub fn generate_route_helper_ancestors_test() {
  let actual =
    generate_helpers.generate_route_helper_body(
      ancestors.singleton(node.Info(name.unsafe("App"), [])),
      [],
      node.Info(name.unsafe("User"), path: [
        node.SegParam(parameter.unsafe_int("id")),
      ]),
    )
    |> doc.join(common.pipe_join())
    |> doc.to_string(80)

  assert actual == "AppUser(app_user_id) |> App"
}

pub fn generate_helpers_rec_test() {
  let root = fixtures.fixture_root()

  let actual =
    generate_helpers.generate_helpers_rec(ancestors.empty(), root)
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_helpers_rec")
}
