import gleam/result
import roundabout/internal/ancestors
import roundabout/internal/parameter.{Int, new, print_name, print_name_and_type}
import roundabout/internal/type_name

pub fn valid_test() {
  assert new("client_id", Int) |> result.map(print_name) == Ok("client_id")

  assert new("clientId", Int) |> result.map(print_name) == Ok("client_id")

  assert new("client id", Int) |> result.map(print_name) == Ok("client_id")

  assert new("CLIENT_ID", Int) |> result.map(print_name) == Ok("client_id")

  assert new("client123", Int) |> result.map(print_name) == Ok("client123")

  assert new("client-id", Int) |> result.map(print_name) == Ok("client_id")
}

pub fn invalid_test() {
  assert new("", Int) == Error("Invalid parameter name ")

  assert new("client_@ID", Int) == Error("Invalid parameter name client_@ID")

  assert new("123", Int) == Error("Invalid parameter name 123")
}

pub fn qualify_name_test() {
  assert parameter.qualify_name(
      ancestors.empty(),
      type_name.unsafe("user"),
      parameter.unsafe_int("id"),
    )
    |> parameter.print_name
    == "user_id"

  assert parameter.qualify_name(
      ancestors.empty(),
      type_name.unsafe("User"),
      parameter.unsafe_int("id"),
    )
    |> parameter.print_name
    == "user_id"

  assert parameter.qualify_name(
      ancestors.singleton(type_name.unsafe("app")),
      type_name.unsafe("user"),
      parameter.unsafe_int("id"),
    )
    |> parameter.print_name
    == "app_user_id"

  assert parameter.qualify_name(
      ancestors.singleton(type_name.unsafe("App")),
      type_name.unsafe("user"),
      parameter.unsafe_int("id"),
    )
    |> parameter.print_name
    == "app_user_id"

  assert parameter.qualify_name(
      ancestors.singleton(type_name.unsafe("BigApp")),
      type_name.unsafe("user"),
      parameter.unsafe_int("id"),
    )
    |> parameter.print_name
    == "big_app_user_id"

  assert parameter.qualify_name(
      ancestors.empty()
        |> ancestors.push(type_name.unsafe("app"))
        |> ancestors.push(type_name.unsafe("members")),
      type_name.unsafe("user"),
      parameter.unsafe_int("id"),
    )
    |> parameter.print_name
    == "app_members_user_id"
}

pub fn print_name_and_type_test() {
  assert parameter.unsafe_int("client_id")
    |> print_name_and_type
    == "client_id: Int"
}
