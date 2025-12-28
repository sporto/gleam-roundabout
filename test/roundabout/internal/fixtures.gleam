import roundabout/internal/fixed
import roundabout/internal/node.{Info, Node, SegFixed, SegParam}
import roundabout/internal/parameter
import roundabout/internal/type_name

pub fn fixture_root() {
  Node(Info(type_name.unsafe(""), []), [
    Node(Info(type_name.unsafe("Home"), []), []),
    Node(
      Info(type_name.unsafe("Orders"), [SegFixed(fixed.unsafe("orders"))]),
      [],
    ),
    Node(
      Info(type_name.unsafe("User"), [
        SegFixed(fixed.unsafe("users")),
        SegParam(parameter.unsafe_int("user_id")),
      ]),
      [
        Node(Info(type_name.unsafe("Show"), []), []),
        Node(
          Info(type_name.unsafe("Delete"), [SegFixed(fixed.unsafe("delete"))]),
          [],
        ),
      ],
    ),
  ])
}
