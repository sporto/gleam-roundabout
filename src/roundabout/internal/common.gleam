import glam/doc
import gleam/list
import gleam/result
import gleam/string
import roundabout/internal/node.{
  type Info, type Node, type Segment, SegFixed, SegParam,
}
import roundabout/internal/parameter
import roundabout/internal/type_name

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

pub fn get_function_name(ancestors: List(Info), info: Info) -> String {
  get_function_name_do([], ancestors, info)
  |> list.filter(fn(seg) { seg != "" })
  |> string.join("_")
}

fn get_function_name_do(
  collected: List(String),
  ancestors: List(Info),
  info: Info,
) {
  let next = list.prepend(collected, type_name.snake(info.name))

  case ancestors {
    [next_ancestor, ..rest_ancestors] -> {
      get_function_name_do(next, rest_ancestors, next_ancestor)
    }
    _ -> next
  }
}

// pub fn get_parameter_name(ancestors: List(Info), info: Info) -> String {
//   get_parameter_name_do([], ancestors, info)
//   |> string.join("")
// }

// fn get_parameter_name_do(
//   collected: List(String),
//   ancestors: List(Info),
//   info: Info,
// ) {
//   let next = list.prepend(collected, type_name.snake(info.name))

//   case ancestors {
//     [next_ancestor, ..rest_ancestors] -> {
//       get_type_name_do(next, rest_ancestors, next_ancestor)
//     }
//     _ -> next
//   }
// }

pub fn get_type_name(ancestors: List(Info), info: Info) -> String {
  get_type_name_do([], ancestors, info)
  |> string.join("")
}

fn get_type_name_do(
  collected: List(String),
  ancestors: List(Info),
  info: Info,
) {
  let next = list.prepend(collected, type_name.name(info.name))

  case ancestors {
    [next_ancestor, ..rest_ancestors] -> {
      get_type_name_do(next, rest_ancestors, next_ancestor)
    }
    _ -> next
  }
}

pub fn segment_to_param(segment: Segment) -> Result(parameter.Parameter, Nil) {
  case segment {
    SegFixed(_) -> Error(Nil)
    SegParam(param) -> {
      Ok(param)
    }
  }
}

pub fn get_function_arguments(
  ancestors: List(Info),
  info: Info,
) -> List(parameter.Parameter) {
  get_function_arguments_rec(ancestors, [], info)
}

fn get_function_arguments_rec(
  ancestors: List(Info),
  acc: List(parameter.Parameter),
  info: Info,
) -> List(parameter.Parameter) {
  let new_params =
    info.path
    |> list.filter_map(segment_to_param)

  let next_acc =
    list.append(new_params, acc)
    |> list.map(parameter.prepend_name(type_name.snake(info.name), _))

  case ancestors {
    [next_ancestor, ..rest_ancestors] ->
      get_function_arguments_rec(rest_ancestors, next_acc, next_ancestor)
    _ -> next_acc
  }
}
