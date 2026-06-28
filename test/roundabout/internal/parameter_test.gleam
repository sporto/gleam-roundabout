import gleam/result
import roundabout/internal/parameter.{Int, name, new, print_name_and_type}

pub fn valid_test() {
  assert new("client_id", Int) |> result.map(name) == Ok("client_id")

  assert new("clientId", Int) |> result.map(name) == Ok("client_id")

  assert new("client id", Int) |> result.map(name) == Ok("client_id")

  assert new("CLIENT_ID", Int) |> result.map(name) == Ok("client_id")

  assert new("client123", Int) |> result.map(name) == Ok("client123")

  assert new("client-id", Int) |> result.map(name) == Ok("client_id")
}

pub fn invalid_test() {
  assert new("", Int) == Error("Invalid parameter name ")

  assert new("client_@ID", Int) == Error("Invalid parameter name client_@ID")

  assert new("123", Int) == Error("Invalid parameter name 123")
}

pub fn prepend_name_test() {
  let actual = parameter.prepend_name("app_users", parameter.unsafe_int("id"))
  assert actual == parameter.unsafe_int("app_users_id")
}

pub fn prepend_name_empty_test() {
  let actual = parameter.prepend_name("", parameter.unsafe_int("id"))
  assert actual == parameter.unsafe_int("id")
}

pub fn print_name_and_type_test() {
  assert new("client_id", Int) |> result.map(print_name_and_type)
    == Ok("client_id: Int")
}
