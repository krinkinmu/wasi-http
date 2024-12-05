load("//bazel:wit.bzl", "rust_wit_library")
load("@rules_rust//rust:defs.bzl", "rust_library")


rust_wit_library(
    name = "bindings",
    wit = "@wasi-http//:wasi-http",
    world = "proxy",
    crate_name = "bindings",
)

rust_library(
    name = "proxy",
    srcs = ["lib.rs"],
    deps = [":bindings"],
    crate_name = "proxy",
)
