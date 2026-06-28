import gleam/result
import roundabout/internal/name.{type_name, new, parameter_name}

pub fn valid_test() {
  assert new("ActiveClients") |> result.map(type_name) == Ok("ActiveClients")

  assert new("active_clients") |> result.map(type_name) == Ok("ActiveClients")

  assert new("active clients") |> result.map(type_name) == Ok("ActiveClients")

  assert new("active-clients") |> result.map(type_name) == Ok("ActiveClients")

  assert new("ACTIVE_CLIENTS") |> result.map(type_name) == Ok("ActiveClients")

  assert new("Client123") |> result.map(type_name) == Ok("Client123")

  assert new("client!") |> result.map(type_name) == Ok("Client")
}

pub fn invalid_test() {
  assert new("") == Error("Invalid name ")

  assert new("!!") == Error("Invalid name !!")

  assert new("123") == Error("Invalid name 123")

  assert new("client_@ID") == Error("Invalid name client_@ID")
}

pub fn snake_test() {
  assert new("ActiveClients") |> result.map(parameter_name) == Ok("active_clients")

  assert new("active-clients") |> result.map(parameter_name) == Ok("active_clients")
}
