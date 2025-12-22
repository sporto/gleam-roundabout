import route_gen.{Int, Lit, RouteDef, Str}

// TODO
// nested routes
// geneate functions to create paths

const routes = [
  RouteDef(name: "home", path: []),
  RouteDef(name: "profile", path: [Lit("profile"), Str("id")]),
  RouteDef(name: "order", path: [Lit("orders"), Int("id")]),
]

pub fn main() {
  route_gen.main(routes, "src/routes.gleam")
}
