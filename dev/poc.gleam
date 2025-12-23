import route_gen.{Int, Lit, RouteDef, Str}

// TODO
// nested routes
// geneate functions to create paths

const routes = [
  RouteDef(name: "home", path: [], sub: []),
  RouteDef(name: "profile", path: [Lit("profile"), Str("id")], sub: []),
  RouteDef(name: "order", path: [Lit("orders"), Int("id")], sub: []),
  RouteDef(
    name: "comment",
    path: [Lit("posts"), Int("postId"), Lit("comments"), Int("commentId")],
    sub: [],
  ),
  RouteDef(
    name: "users",
    path: [Lit("users"), Int("id")],
    sub: [RouteDef(name: "new", path: [Lit("new")], sub: [])],
  ),
]

pub fn main() {
  echo route_gen.main(routes, "dev/generated.gleam")
}
