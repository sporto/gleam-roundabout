import birdie
import glam/doc
import roundabout/internal/fixtures
import roundabout/internal/generate_types
import roundabout/internal/node.{Info, Node, SegParam}
import roundabout/internal/parameter
import roundabout/internal/type_name

pub fn generate_type_root_test() {
  let root = fixtures.fixture_root()
  let actual = generate_types.generate_type([], root)

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_type_root")
}

pub fn generate_type_child_test() {
  let ancestors = [Info(name: type_name.unsafe("Client"), path: [])]

  let assert Ok(par_id) = parameter.new("id", parameter.Int)

  let node =
    Node(info: Info(name: type_name.unsafe("User"), path: []), children: [
      Node(
        info: Info(name: type_name.unsafe("Show"), path: [SegParam(par_id)]),
        children: [],
      ),
    ])

  let actual = generate_types.generate_type(ancestors, node)

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_type_child")
}

pub fn generate_type_rec_test() {
  let root = fixtures.fixture_root()
  let actual = generate_types.generate_type_rec([], root)

  actual
  |> doc.to_string(80)
  |> birdie.snap(title: "generate_type_rec")
}
