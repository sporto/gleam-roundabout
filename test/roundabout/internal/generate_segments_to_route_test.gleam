import birdie
import glam/doc
import roundabout/internal/ancestors
import roundabout/internal/fixtures
import roundabout/internal/generate_segments_to_route

/// generate_segments_to_route
///
pub fn generate_segments_to_route_root_test() {
  let root = fixtures.fixture_root()
  let actual =
    generate_segments_to_route.generate_segments_to_route(
      ancestors.empty(),
      root,
    )

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_segments_to_route_root")
}

pub fn generate_segments_to_route_rec_test() {
  let root = fixtures.fixture_root()

  let actual =
    generate_segments_to_route.generate_segments_to_route_rec(
      ancestors.empty(),
      root,
    )
    |> doc.to_string(80)

  actual
  |> birdie.snap(title: "generate_segments_to_route_rec")
}
