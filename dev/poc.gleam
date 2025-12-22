import route_gen.{Int, Lit, RouteDef, Str}

// TODO
// nested routes
// geneate functions to create paths

const routes = [
  RouteDef(name: "home", path: []),
  RouteDef(name: "profile", path: [Lit("profile"), Str("id")]),
  RouteDef(name: "order", path: [Lit("orders"), Int("id")]),
  RouteDef(
    name: "comments",
    path: [Lit("posts"), Int("postId"), Lit("comments"), Int("commentId")],
  ),
]

pub fn main() {
  echo route_gen.main(routes, "dev/generated.gleam")
}
