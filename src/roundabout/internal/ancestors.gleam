import gleam/list

/// Ancestors is a stack, the first one is the parent
pub opaque type Ancestors(a) {
  Ancestors(ancestors: List(a))
}

pub fn empty() {
  Ancestors([])
}

pub fn singleton(a: a) {
  Ancestors([a])
}

pub fn filter(ancestors: Ancestors(a), fun) {
  Ancestors(list.filter(ancestors.ancestors, fun))
}

pub fn map(ancestors: Ancestors(a), fun) {
  Ancestors(list.map(ancestors.ancestors, fun))
}

pub fn push(ancestors: Ancestors(a), a) {
  Ancestors(list.prepend(ancestors.ancestors, a))
}

pub fn pop(ancestors: Ancestors(a)) {
  case ancestors.ancestors {
    [next_ancestor, ..rest_ancestors] ->
      Ok(#(next_ancestor, Ancestors(rest_ancestors)))
    _ -> Error(Nil)
  }
}

pub fn is_empty(ancestors: Ancestors(a)) {
  list.is_empty(ancestors.ancestors)
}

// Returns the list of ancestors
// with the top first, parent last
pub fn to_list(ancestors: Ancestors(a)) {
  ancestors.ancestors
  |> list.reverse
}
