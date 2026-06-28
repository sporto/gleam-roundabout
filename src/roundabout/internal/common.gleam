import glam/doc
import gleam/list
import gleam/result
import gleam/string
import roundabout/internal/ancestors.{type Ancestors}
import roundabout/internal/node.{
  type Info, type Node, type Segment, SegFixed, SegParam,
}
import roundabout/internal/parameter
import roundabout/internal/qualified.{type Qualified, type Unqualified}
import roundabout/internal/name

pub const double_quote = "\""

pub const forward_slash = "\"/\""

/// Join two strings with <>
/// We allow breaking just before
pub fn string_join() {
  doc.flex_break(" ", "")
  |> doc.append(doc.from_string("<> "))
}

pub fn pipe_join() {
  doc.flex_break(" ", "")
  |> doc.append(doc.from_string("|> "))
}

pub fn case_arrow() {
  doc.from_string(" ->")
  |> doc.append(doc.flex_break(" ", ""))
}

/// Generate a function name like
/// app_client_user
pub fn generate_function_name(
  ancestors: Ancestors(Info),
  info: Info,
) -> String {
  let ancestors = ancestors.map(ancestors, fn(a) { a.name })
  qualify(ancestors, info.name, name.AsParameterName)
}

/// Generate a type name like
/// AppClientUser
pub fn generate_type_name(ancestors: Ancestors(Info), info: Info) -> String {
  let ancestors = ancestors.map(ancestors, fn(a) { a.name })
  qualify(ancestors, info.name, name.AsTypeName)
}

// pub fn qualify_parameter(
//   ancestors: Ancestors(Info),
//   info: Info,
//   p: parameter.Parameter(Unqualified),
// ) {
//   let ancestors =
//     ancestors.map(ancestors, fn(a) { a.name })
//     |> ancestors.push(info.name)

//   let new_name =
//     qualify(
//       ancestors,
//       type_name.unsafe(parameter.print_name(p)),
//       type_name.AsParameterName,
//     )
// }

fn qualify(
  ancestors: Ancestors(name.Name),
  node: name.Name,
  using: name.AsName,
) {
  let to_name = case using {
    name.AsParameterName -> name.parameter_name
    name.AsTypeName -> name.type_name
  }

  let join = case using {
    name.AsParameterName -> "_"
    name.AsTypeName -> ""
  }

  ancestors
  |> ancestors.filter(fn(a) { !name.is_root(a) })
  |> ancestors.push(node)
  |> ancestors.map(to_name)
  |> ancestors.to_list
  |> string.join(join)
}

pub fn segment_to_param(
  segment: Segment,
) -> Result(parameter.Parameter(Unqualified), Nil) {
  case segment {
    SegFixed(_) -> Error(Nil)
    SegParam(param) -> {
      Ok(param)
    }
  }
}

pub fn get_function_arguments(
  ancestors: Ancestors(Info),
  info: Info,
) -> List(parameter.Parameter(Qualified)) {
  get_function_arguments_rec(ancestors, [], info)
}

fn get_function_arguments_rec(
  ancestors: Ancestors(Info),
  acc: List(parameter.Parameter(Qualified)),
  info: Info,
) -> List(parameter.Parameter(Qualified)) {
  let ancestors_names = ancestors.map(ancestors, fn(a) { a.name })

  let new_params =
    info.path
    |> list.filter_map(segment_to_param)
    |> list.map(parameter.qualify_name(ancestors_names, info.name, _))

  let next_acc = list.append(new_params, acc)

  case ancestors.pop(ancestors) {
    Ok(#(next_ancestor, rest_ancestors)) ->
      get_function_arguments_rec(rest_ancestors, next_acc, next_ancestor)
    Error(_) -> next_acc
  }
}
