import roundabout/internal/fixed
import roundabout/internal/node.{Info, Node, SegFixed, SegParam}
import roundabout/internal/parameter
import roundabout/internal/name

pub fn fixture_root() {
  Node(Info(name.unsafe(""), []), [
    Node(Info(name.unsafe("Home"), []), []),
    Node(
      Info(name.unsafe("Orders"), [SegFixed(fixed.unsafe("orders"))]),
      [],
    ),
    Node(
      Info(name.unsafe("Products"), [SegFixed(fixed.unsafe("products"))]),
      [
        Node(
          Info(name.unsafe("Product"), [
            SegParam(parameter.unsafe_int("id")),
          ]),
          [],
        ),
      ],
    ),
    Node(
      Info(name.unsafe("User"), [
        SegFixed(fixed.unsafe("users")),
        SegParam(parameter.unsafe_int("id")),
      ]),
      [
        Node(Info(name.unsafe("Show"), []), []),
        Node(
          Info(name.unsafe("Delete"), [SegFixed(fixed.unsafe("delete"))]),
          [],
        ),
      ],
    ),
  ])
}
