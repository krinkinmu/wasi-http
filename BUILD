load("//bazel:wit.bzl", "rust_wit_library")

rust_wit_library(
    name = "proxy",
    wit = "@wasi-http//:wasi-http",
    world = "proxy",
    crate_name = "proxy",
)

cc_binary(
    name = "test.wasm",
    srcs = ["test.cc"],
    linkopts = [
        "-mexec-model=reactor",
    ],
    deps = [
        "//proxy-wasm-cpp-sdk:proxy-wasm",
    ],
)
