import roundabout/internal/ancestors
import roundabout/internal/common
import roundabout/internal/node.{Info}
import roundabout/internal/parameter
import roundabout/internal/type_name

pub fn get_type_name_test() {
  let actual =
    common.get_type_name(
      ancestors.singleton(Info(name: type_name.unsafe("Client"), path: [])),
      Info(name: type_name.unsafe("SimpleUser"), path: []),
    )

  assert actual == "ClientSimpleUser"
}

pub fn generate_function_name_test() {
  let actual =
    common.generate_function_name(
      ancestors.singleton(Info(name: type_name.unsafe("Client"), path: [])),
      Info(name: type_name.unsafe("SimpleUser"), path: []),
    )

  assert actual == "client_simple_user"
}

pub fn get_function_arguments_test() {
  let actual =
    common.get_function_arguments(
      ancestors.empty()
        |> ancestors.push(Info(name: type_name.unsafe("App"), path: []))
        |> ancestors.push(Info(name: type_name.unsafe("Users"), path: [])),
      Info(name: type_name.unsafe("User"), path: [
        node.SegParam(parameter.unsafe_int("id")),
        node.SegParam(parameter.unsafe_str("status")),
      ]),
    )

  let expected = [
    parameter.unsafe_int("app_users_user_id"),
    parameter.unsafe_str("app_users_user_status"),
  ]

  assert actual == expected
}
