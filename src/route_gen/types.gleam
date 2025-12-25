import route_gen/parameter_name.{type ParameterName}

@internal
pub type Segment {
  SegLit(name: String)
  SegStr(name: ParameterName)
  SegInt(name: ParameterName)
}

@internal
pub type Info {
  Info(name: String, path: List(Segment))
}

@internal
pub type Node {
  Node(info: Info, sub: List(Node))
}
