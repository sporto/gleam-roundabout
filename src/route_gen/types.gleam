@internal
pub type Segment {
  SegLit(name: String)
  SegStr(name: String)
  SegInt(name: String)
}

@internal
pub type Info {
  Info(name: String, segments: List(Segment))
}

@internal
pub type Node {
  Node(children: List(Node), info: Info)
}
