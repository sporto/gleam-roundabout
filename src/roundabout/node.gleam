import roundabout/constant
import roundabout/parameter
import roundabout/type_name

@internal
pub type Segment {
  SegLit(value: constant.Constant)
  SegParam(name: parameter.Parameter)
}

@internal
pub type Info {
  Info(name: type_name.TypeName, path: List(Segment))
}

@internal
pub type Node {
  Node(info: Info, sub: List(Node))
}
