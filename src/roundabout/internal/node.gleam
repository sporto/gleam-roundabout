import roundabout/internal/constant
import roundabout/internal/parameter
import roundabout/internal/type_name

pub type Segment {
  SegLit(value: constant.Constant)
  SegParam(name: parameter.Parameter)
}

pub type Info {
  Info(name: type_name.TypeName, path: List(Segment))
}

pub type Node {
  Node(info: Info, children: List(Node))
}
