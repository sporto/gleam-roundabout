import roundabout.{Int, Lit, Route, Str}

const routes = [
  Route(name: "home", path: [], children: []),
  Route(name: "profile", path: [Lit("profile"), Str("id")], children: []),
  Route(name: "my_orders", path: [Lit("my-orders")], children: []),
  Route(name: "order", path: [Lit("orders"), Int("id")], children: []),
  Route(
    name: "comment",
    path: [Lit("posts"), Int("postId"), Lit("comments"), Int("commentId")],
    children: [],
  ),
  Route(
    name: "user",
    path: [Lit("users"), Int("id")],
    children: [
      Route(name: "show", path: [], children: []),
      Route(name: "activate", path: [Lit("new")], children: []),
    ],
  ),
]

pub fn main() {
  roundabout.main(routes, "src/example_app/generated/routes")
}
