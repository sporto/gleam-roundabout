import gleam/result
import roundabout/internal/fixed.{new, value}

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
  assert new("") == Error("Invalid fixed value ")

  assert new("active/clients") == Error("Invalid fixed value active/clients")

  assert new("active clients") == Error("Invalid fixed value active clients")

  assert new("client!") == Error("Invalid fixed value client!")

  assert new("client$") == Error("Invalid fixed value client$")

  assert new("client&") == Error("Invalid fixed value client&")

  assert new("client#") == Error("Invalid fixed value client#")

  assert new("client?") == Error("Invalid fixed value client?")
}
