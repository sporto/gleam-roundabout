import route_gen/parameter.{type Parameter}

@internal
pub type Segment {
  SegLit(name: String)
  SegParam(name: Parameter)
}

@internal
pub type Info {
  Info(name: String, path: List(Segment))
}

@internal
pub type Node {
  Node(info: Info, sub: List(Node))
}
