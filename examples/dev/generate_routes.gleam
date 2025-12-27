import roundabout.{fixed, int, route, str}

pub fn main() {
  let routes = [
    route("home", [], children: []),
    route("profile", [fixed("profile"), str("id")], children: []),
    route("my_orders", [fixed("my-orders")], children: []),
    route("order", [fixed("orders"), int("id")], children: []),
    route(
      "comment",
      [fixed("posts"), int("postId"), fixed("comments"), int("commentId")],
      children: [],
    ),
    route("user", [fixed("users"), int("id")], children: [
      route("show", [], children: []),
      route("activate", [fixed("new")], children: []),
    ]),
  ]

  roundabout.main(routes, "src/example_app/generated/routes")
}
