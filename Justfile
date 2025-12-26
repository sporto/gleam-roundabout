example-gen:
    cd examples && gleam run -m generate_routes

example-check:
    cd examples && gleam check

example-test:
    cd examples && gleam test

snaps:
    gleam run -m birdie

test:
    gleam test
