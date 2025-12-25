import gleam/result
import routegen/parameter.{Int, name, new}

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
