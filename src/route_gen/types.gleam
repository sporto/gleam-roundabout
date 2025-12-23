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
pub type ContributionInfo {
  ContributionInfo(type_name: String, func_name: String)
}

@internal
pub type Contribution {
  Contribution(
    ancestors: List(ContributionInfo),
    children: List(Contribution),
    info: ContributionInfo,
  )
}
