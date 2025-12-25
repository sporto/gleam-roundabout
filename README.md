# route_gen

[![Package Version](https://img.shields.io/hexpm/v/route_gen)](https://hex.pm/packages/route_gen)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/route_gen/)

A route generator for Gleam.

## Why

Gleam gives us a great way of matching paths via pattern matching:

```gleam
pub type Route {
    Users
    User(id: String)
    NotFound
}

pub fn get_route(segments: List(String)) {
    case segments {
        Ok(["users"]) -> Users
        Ok(["users", id]) -> User(id)
        _ -> NotFound
     }
}
```

However, this doesn't provide a type safe way of constructing a path from type e.g. 

```
User("12") -> "/users/12"
```

See <https://www.kurz.net/posts/gleam-routing> for a more detailed explanation.

This packages provides a generator which gives you:

- A function for converting paths to Route types (`segments_to_route`)
- A function for converting Route types to paths (`route_to_path`)
- Helpers for generating route types and paths for each route

## Install

```sh
gleam add route_gen@1
```

## Generating routes

Create a module in your project which defines the route definitions and calls the generator. e.g. in `src/gen_routes.gleam`

```gleam
import route_gen.{Int, Lit, Route, Str}

const routes = [
  Route(name: "home", path: [], sub: []),
  // Will match an individual order e.g. /orders/123
  Route(name: "order", path: [Lit("orders"), Int("id")], sub: []),
  Route(
    name: "user",
    path: [Lit("users"), Int("id")],
    sub: [
      // Will match /users/123
      Route(name: "show", path: [], sub: []),
      // Will match /users/123/delete
      Route(name: "delete", path: [Lit("delete")], sub: []),
    ],
  ),
]

pub fn main() -> Nil {
    route_gen.main(routes, "src/generated/routes.gleam")
}
```

Call this using:
```sh
gleam run -m gen_routes
```

See example output at `examples/src/generated/routes.gleam`

## The order is important

If you have routes like:

```gleam
[
    Route(name: "show", path: [Str("id")], sub: []),
    Route(name: "invite", path: [Lit("invite")], sub: []),
]
```
The first one will always match over the second one, make sure that literal routes are first.

---

Further documentation can be found at <https://hexdocs.pm/route_gen>.

## TODO

- Format better
- Generate example when pushing
- Add test to ensure example type checks
