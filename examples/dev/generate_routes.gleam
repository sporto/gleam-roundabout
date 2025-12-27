import roundabout.{Int, Lit, Route, Str}

const routes = [
  Route("home", path: [], children: []),
  Route("profile", path: [Lit("profile"), Str("id")], children: []),
  Route("my_orders", path: [Lit("my-orders")], children: []),
  Route("order", path: [Lit("orders"), Int("id")], children: []),
  Route(
    "comment",
    path: [Lit("posts"), Int("postId"), Lit("comments"), Int("commentId")],
    children: [],
  ),
  Route(
    "user",
    path: [Lit("users"), Int("id")],
    children: [
      Route("show", path: [], children: []),
      Route("activate", path: [Lit("new")], children: []),
    ],
  ),
]

pub fn main() {
  roundabout.main(routes, "src/example_app/generated/routes")
}
