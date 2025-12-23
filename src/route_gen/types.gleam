import gleam/option

@internal
pub type InputSegment {
  Lit(val: String)
  Str(name: String)
  Int(name: String)
}

@internal
pub type InputDef {
  InputDef(name: String, path: List(InputSegment), sub: List(InputDef))
}

@internal
pub type ParamKind {
  ParamInt
  ParamStr
}

@internal
pub type Param {
  Param(name: String, kind: ParamKind)
}

@internal
pub type Info {
  Info(
    ancestor: option.Option(Info),
    name: String,
    segment_params: List(Param),
    segments: List(InputSegment),
  )
}

@internal
pub type Node {
  Node(children: List(Node), info: Info)
}
