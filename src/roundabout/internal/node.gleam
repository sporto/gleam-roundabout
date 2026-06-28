import roundabout/internal/fixed
import roundabout/internal/parameter
import roundabout/internal/qualified
import roundabout/internal/name

pub type Segment {
  SegFixed(value: fixed.Fixed)
  SegParam(name: parameter.Parameter(qualified.Unqualified))
}

pub type Info {
  Info(name: name.Name, path: List(Segment))
}

pub type Node {
  Node(info: Info, children: List(Node))
}
