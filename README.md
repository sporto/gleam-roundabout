![Roundabout](assets/roundabout.jpeg)
# Roundabout
A route generator for Gleam.

[![Package Version](https://img.shields.io/hexpm/v/roundabout)](https://hex.pm/packages/roundabout)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/roundabout/)

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
    ["users"] -> Users
    ["users", id] -> User(id)
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

This generator can be used in frontend or backend applications, at it only generates the route types and helper functions. You still need to write your own router using these types.

## Install

```sh
gleam add roundabout@1
```

## Generating routes

Create a module in your project which defines the route definitions and calls the generator. e.g. in `dev/generate_routes.gleam`

```gleam
import roundabout.{Int, Lit, Route, Str}

const routes = [
  Route(name: "home", path: [], children: []),
  // Will match an individual order e.g. /orders/123
  Route(name: "order", path: [Lit("orders"), Int("id")], children: []),
  Route(
    name: "user",
    path: [Lit("users"), Int("id")],
    children: [
      // Will match /users/123
      Route(name: "show", path: [], children: []),
      // Will match /users/123/delete
      Route(name: "delete", path: [Lit("delete")], children: []),
    ],
  ),
]

pub fn main() -> Nil {
  roundabout.main(routes, "src/my_app/generated/routes")
}
```

Call this using:
```sh
gleam run -m generate_routes
```

See example output at `examples/src/example_app/generated/routes.gleam`

## Using this in your application

After the routes have been generated, you can use them in your router or views like:

```gleam
import generated/routes

pub fn handle(segments: List(String)) {
  let maybe_route = routes.segments_to_route(segments)

  case maybe_route {
    Ok(routes.Home) -> handle_home()
    Ok(routes.Order(id)) -> handle_order(id)
    ...
    Error(_) -> handle_not_found()
  }
} 
```

## Notes

### The order is important

If you have routes like:

```gleam
[
  Route(name: "show", path: [Str("id")], children: []),
  Route(name: "invite", path: [Lit("invite")], children: []),
]
```
The first one will always match over the second one, make sure that literal routes are first.

## Structure your routes to support your middleware

If you want to use different middlewares at different levels of your application, you can structure your routes to support this.

For example, having:

```gleam
const routes = [
  Route(name: "home", path: [], children: []),
  Route(
    name: "app",
    path: [Lit("app")],
    children: [
      // Will match /app/
      Route(name: "dashboard", path: [], children: []),
    ],
  ),
]
```

Allows to apply some middleware for authentication like:

```gleam
import generated/routes
import middleware
import wisp

pub fn handle(req: Request,, ctx: Context) {
  let segments = wisp.path_segments(req)
  let maybe_route = routes.segments_to_route(segments)

  case maybe_route {
    Ok(routes.Home) -> handle_home()
    Ok(routes.App(sub)) -> {
      use authenticated_context <- middleware.require_session(req, ctx)
    
      case sub {
        routes.Dashboard -> handle_dashboard(authenticated_context)
      }
    }
    ...
    Error(_) -> handle_not_found()
  }
} 
```

---

Further documentation can be found at <https://hexdocs.pm/roundabout>.
