import generated/routes
import gleam/list
import gleam/string

fn test_to_route(path: String, route) {
  let segments =
    string.split(path, "/")
    |> list.filter(fn(s) { !string.is_empty(s) })

  assert routes.segments_to_route(segments) == Ok(route) as path
}

fn test_to_path(path: String, route) {
  let actual = routes.route_to_path(route)
  assert actual == path
}

fn test_roundtrip(path: String, route) {
  test_to_route(path, route)
  test_to_path(path, route)
}

pub fn route_round_trips_test() {
  test_to_route("", routes.Home)
  test_roundtrip("/", routes.Home)
  test_roundtrip("/profile/me", routes.Profile("me"))
  test_roundtrip("/my-orders", routes.MyOrders)
  test_roundtrip("/orders/12", routes.Order(12))
  test_roundtrip("/posts/1/comments/2", routes.Comment(1, 2))
  test_roundtrip("/users/1", routes.User(1, routes.UserShow))
  test_roundtrip("/users/1/new", routes.User(1, routes.UserActivate))
}
