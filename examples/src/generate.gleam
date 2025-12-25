import route_gen.{Int, Lit, Route, Str}

const routes = [
  Route(name: "home", path: [], sub: []),
  Route(name: "profile", path: [Lit("profile"), Str("id")], sub: []),
  Route(name: "order", path: [Lit("orders"), Int("id")], sub: []),
  Route(
    name: "comment",
    path: [Lit("posts"), Int("postId"), Lit("comments"), Int("commentId")],
    sub: [],
  ),
  Route(
    name: "user",
    path: [Lit("users"), Int("id")],
    sub: [
      Route(name: "show", path: [], sub: []),
      Route(name: "new", path: [Lit("new")], sub: []),
    ],
  ),
]

pub fn main() {
  route_gen.main(routes, "src/generated/routes.gleam")
}
