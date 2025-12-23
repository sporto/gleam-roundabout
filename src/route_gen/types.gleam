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
pub type ContributionInfo {
  ContributionInfo(
    ancestor: option.Option(ContributionInfo),
    name: String,
    segment_params: List(Param),
  )
}

@internal
pub type NotNamespaced

pub type Namespaced

@internal
pub type Contribution(a) {
  Contribution(children: List(Contribution(a)), info: ContributionInfo)
}
