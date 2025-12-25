import gleam/result
import gleeunit
import route_gen.{Int, Lit, Route, Str}
import route_gen/parameter
import route_gen/types.{Info, Node, SegLit, SegParam}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_success_test() {
  let input = [
    Route(name: "home", path: [], sub: []),
    Route(name: "client", path: [Lit("clients"), Int("clientId")], sub: [
      Route(name: "show", path: [], sub: []),
      Route(name: "orders", path: [Lit("orders")], sub: [
        Route(name: "index", path: [], sub: []),
        Route(name: "show", path: [Int("orderId")], sub: []),
      ]),
    ]),
  ]

  let assert Ok(par_client_id) = parameter.new("clientId", parameter.Int)
  let assert Ok(par_order_id) = parameter.new("orderId", parameter.Int)

  let expected =
    Node(info: Info(name: "", path: []), sub: [
      Node(info: Info(name: "home", path: []), sub: []),
      Node(
        info: Info(name: "client", path: [
          SegLit("clients"),
          SegParam(par_client_id),
        ]),
        sub: [
          Node(info: Info(name: "show", path: []), sub: []),
          Node(info: Info(name: "orders", path: [SegLit("orders")]), sub: [
            Node(info: Info(name: "index", path: []), sub: []),
            Node(
              info: Info(name: "show", path: [SegParam(par_order_id)]),
              sub: [],
            ),
          ]),
        ],
      ),
    ])

  let actual = route_gen.parse(input)

  assert actual == Ok(expected)
}

pub fn parse_fail_duplicate_route_names_test() {
  let input = [
    Route(name: "clients", path: [Lit("clients")], sub: [
      Route(name: "ClientIndex", path: [], sub: []),
      Route(name: "client_index", path: [], sub: []),
    ]),
  ]

  let actual = route_gen.parse(input)

  assert actual == Error("Route clients contain duplicate route names")
}

pub fn parse_fail_duplicate_segment_names_test() {
  let input = [
    Route(name: "clients", path: [Lit("clients")], sub: [
      Route(name: "show", path: [Str("client_id"), Int("ClientID")], sub: []),
    ]),
  ]

  let actual = route_gen.parse(input)

  assert actual == Error("Route show contain duplicate segment names")
}

pub fn parse_success_duplicate_literal_segment_names_test() {
  let input = [
    Route(name: "clients", path: [Lit("clients")], sub: [
      Route(
        name: "show",
        path: [
          Lit("client_id"),
          Lit("client_id"),
          Str("client_id"),
        ],
        sub: [],
      ),
    ]),
  ]

  let actual = route_gen.parse(input)

  assert result.is_ok(actual) == True
}
