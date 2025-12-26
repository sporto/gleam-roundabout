import glam/doc.{type Document}

@internal
pub fn generate_header() {
  "//// This module was generated using roundabout.
////
"
  |> doc.from_string
  |> doc.append(doc.line)
}

@internal
pub fn generate_imports() -> Document {
  [
    doc.from_string("import gleam/int"),
    doc.line,
    doc.from_string("import gleam/result"),
    doc.lines(2),
  ]
  |> doc.concat
}

@internal
pub fn generate_utils() -> Document {
  "
fn with_int(str: String, fun) {
    int.parse(str)
    |> result.try(fun)
}
"
  |> doc.from_string
}
