import roundabout/internal/fixed
import roundabout/internal/parameter
import roundabout/internal/type_name

pub type Segment {
  SegFixed(value: fixed.Fixed)
  SegParam(name: parameter.Parameter)
}

pub type Info {
  Info(name: type_name.TypeName, path: List(Segment))
}

pub type Node {
  Node(info: Info, children: List(Node))
}
