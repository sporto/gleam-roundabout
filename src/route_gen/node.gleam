import route_gen/constant
import route_gen/parameter
import route_gen/type_name

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
