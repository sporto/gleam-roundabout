import gleam/result
import route_gen/constant.{new, value}

pub fn valid_test() {
  assert new("clients") |> result.map(value) == Ok("clients")

  assert new("active_clients") |> result.map(value) == Ok("active_clients")

  assert new("active-clients") |> result.map(value) == Ok("active-clients")

  assert new("ActiveClients") |> result.map(value) == Ok("activeclients")

  assert new("123") |> result.map(value) == Ok("123")

  assert new("1.2") |> result.map(value) == Ok("1.2")

  assert new("~client") |> result.map(value) == Ok("~client")

  assert new("active%20clients") |> result.map(value) == Ok("active%20clients")
}

pub fn invalid_test() {
  assert new("") == Error("Invalid constant value ")

  assert new("active clients") == Error("Invalid constant value active clients")

  assert new("client!") == Error("Invalid constant value client!")

  assert new("client$") == Error("Invalid constant value client$")

  assert new("client&") == Error("Invalid constant value client&")

  assert new("client#") == Error("Invalid constant value client#")

  assert new("client?") == Error("Invalid constant value client?")
}
