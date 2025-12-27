import gleam/result
import gleeunit
import roundabout.{Fixed, Int, Route, Str}
import roundabout/internal/constant
import roundabout/internal/node.{Info, Node, SegFixed, SegParam}
import roundabout/internal/parameter
import roundabout/internal/type_name

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_success_test() {
  let input = [
    Route(name: "home", path: [], children: []),
    Route(name: "client", path: [Fixed("clients"), Int("clientId")], children: [
      Route(name: "show", path: [], children: []),
      Route(name: "orders", path: [Fixed("orders")], children: [
        Route(name: "index", path: [], children: []),
        Route(name: "show", path: [Int("orderId")], children: []),
      ]),
    ]),
  ]

  let assert Ok(par_client_id) = parameter.new("clientId", parameter.Int)
  let assert Ok(par_order_id) = parameter.new("orderId", parameter.Int)

  let expected =
    Node(info: Info(name: type_name.unsafe(""), path: []), children: [
      Node(info: Info(name: type_name.unsafe("Home"), path: []), children: []),
      Node(
        info: Info(name: type_name.unsafe("Client"), path: [
          SegFixed(constant.unsafe("clients")),
          SegParam(par_client_id),
        ]),
        children: [
          Node(
            info: Info(name: type_name.unsafe("Show"), path: []),
            children: [],
          ),
          Node(
            info: Info(name: type_name.unsafe("Orders"), path: [
              SegFixed(constant.unsafe("orders")),
            ]),
            children: [
              Node(
                info: Info(name: type_name.unsafe("Index"), path: []),
                children: [],
              ),
              Node(
                info: Info(name: type_name.unsafe("Show"), path: [
                  SegParam(par_order_id),
                ]),
                children: [],
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
    Route(name: "clients", path: [Fixed("clients")], children: [
      Route(name: "ClientIndex", path: [], children: []),
      Route(name: "client_index", path: [], children: []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Route clients contain duplicate route names")
}

pub fn parse_fail_invalid_route_name_test() {
  let input = [
    Route(name: "clients", path: [Fixed("clients")], children: [
      Route(name: "123show", path: [], children: []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Invalid type name 123show")
}

pub fn parse_fail_duplicate_segment_names_test() {
  let input = [
    Route(name: "clients", path: [Fixed("clients")], children: [
      Route(
        name: "show",
        path: [Str("client_id"), Int("ClientID")],
        children: [],
      ),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Route show contain duplicate segment names")
}

pub fn parse_success_duplicate_literal_segment_names_test() {
  let input = [
    Route(name: "clients", path: [Fixed("clients")], children: [
      Route(
        name: "show",
        path: [
          Fixed("client_id"),
          Fixed("client_id"),
          Str("client_id"),
        ],
        children: [],
      ),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert result.is_ok(actual) == True
}

pub fn parse_fail_invalid_param_name_test() {
  let input = [
    Route(name: "clients", path: [Fixed("clients")], children: [
      Route(name: "show", path: [Str("1id")], children: []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Invalid parameter name 1id")
}

pub fn parse_fail_invalid_literal_test() {
  let input = [
    Route(name: "clients", path: [Fixed("clients")], children: [
      Route(name: "show", path: [Fixed("?lit")], children: []),
    ]),
  ]

  let actual = roundabout.parse(input)

  assert actual == Error("Invalid constant value ?lit")
}
