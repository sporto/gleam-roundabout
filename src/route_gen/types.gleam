@internal
pub type Segment {
  SegLit(name: String)
  SegStr(name: String)
  SegInt(name: String)
}

@internal
pub type Info {
  Info(name: String, path: List(Segment))
}

@internal
pub type Node {
  Node(sub: List(Node), info: Info)
}
