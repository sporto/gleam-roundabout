import roundabout/internal/common
import roundabout/internal/node.{Info}
import roundabout/internal/parameter
import roundabout/internal/type_name

pub fn get_type_name_test() {
  let actual =
    common.get_type_name(
      [Info(name: type_name.unsafe("Client"), path: [])],
      Info(name: type_name.unsafe("SimpleUser"), path: []),
    )

  assert actual == "ClientSimpleUser"
}

pub fn get_function_name_test() {
  let actual =
    common.get_function_name(
      [Info(name: type_name.unsafe("Client"), path: [])],
      Info(name: type_name.unsafe("SimpleUser"), path: []),
    )

  assert actual == "client_simple_user"
}

pub fn get_function_arguments_test() {
  let actual =
    common.get_function_arguments(
      [
        Info(name: type_name.unsafe("Users"), path: []),
        Info(name: type_name.unsafe("App"), path: []),
      ],
      Info(name: type_name.unsafe("User"), path: [
        node.SegParam(parameter.unsafe_int("id")),
      ]),
    )

  let expected = [
    parameter.unsafe_int("app_users_user_id"),
  ]

  assert actual == expected
}
