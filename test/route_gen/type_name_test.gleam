import gleam/result
import route_gen/type_name.{name, new, snake}

pub fn valid_test() {
  assert new("ActiveClients") |> result.map(name) == Ok("ActiveClients")

  assert new("active_clients") |> result.map(name) == Ok("ActiveClients")

  assert new("active clients") |> result.map(name) == Ok("ActiveClients")

  assert new("active-clients") |> result.map(name) == Ok("ActiveClients")

  assert new("Client123") |> result.map(name) == Ok("Client123")

  assert new("client!") |> result.map(name) == Ok("Client")
}

pub fn invalid_test() {
  assert new("") == Error("Invalid type name ")

  assert new("!!") == Error("Invalid type name !!")

  assert new("123") == Error("Invalid type name 123")
}

pub fn snake_test() {
  assert new("ActiveClients") |> result.map(snake) == Ok("active_clients")

  assert new("active-clients") |> result.map(snake) == Ok("active_clients")
}
