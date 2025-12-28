import gleam/result
import gleeunit
import roundabout.{fixed, int, route, str}
import roundabout/internal/constant
import roundabout/internal/node.{Info, Node, SegFixed, SegParam}
import roundabout/internal/parameter
import roundabout/internal/type_name

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_success_test() {
  let input = [
    route("home", [], []),
    route("client", [fixed("clients"), int("clientId")], [
      route("show", [], []),
      route("orders", [fixed("orders")], [
        route("index", [], []),
        route("show", [int("orderId")], []),
      ]),
    ]),
  ]

  let assert Ok(par_client_id) = parameter.new("clientId", parameter.Int)
  let assert Ok(par_order_id) = parameter.new("orderId", parameter.Int)

  let expected =
    Node(Info(type_name.unsafe(""), []), [
      Node(Info(type_name.unsafe("Home"), []), []),
      Node(
        Info(type_name.unsafe("Client"), [
          SegFixed(constant.unsafe("clients")),
          SegParam(par_client_id),
        ]),
        [
          Node(Info(type_name.unsafe("Show"), []), []),
          Node(
            Info(type_name.unsafe("Orders"), [
              SegFixed(constant.unsafe("orders")),
            ]),
            [
              Node(Info(type_name.unsafe("Index"), []), []),
              Node(
                Info(type_name.unsafe("Show"), [
                  SegParam(par_order_id),
                ]),
                [],
              ),
            ],
          ),
        ],
      ),
    ])

  let actual = roundabout.parse(input)

  assert actual == Ok(expected)
}

pub fn parse_fail_duplicate_route_names_test() {
  let input = [
    route("clients", [fixed("clients")], [
      route("ClientIndex", [], []),
      route("client_index", [], []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Route clients contains duplicate route names")
}

pub fn parse_fail_invalid_route_name_test() {
  let input = [
    route("clients", [fixed("clients")], [
      route("123show", [], []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Invalid type name 123show")
}

pub fn parse_fail_duplicate_segment_names_test() {
  let input = [
    route("clients", [fixed("clients")], [
      route("show", [str("client_id"), int("ClientID")], []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Route show contains duplicate segment names")
}

pub fn parse_success_duplicate_literal_segment_names_test() {
  let input = [
    route("clients", [fixed("clients")], [
      route(
        "show",
        [
          fixed("client_id"),
          fixed("client_id"),
          str("client_id"),
        ],
        [],
      ),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert result.is_ok(actual) == True
}

pub fn parse_fail_invalid_param_name_test() {
  let input = [
    route("clients", [fixed("clients")], [
      route("show", [str("1id")], []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Invalid parameter name 1id")
}

pub fn parse_fail_invalid_literal_test() {
  let input = [
    route("clients", [fixed("clients")], [
      route("show", [fixed("?lit")], []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Invalid constant value ?lit")
}
