load("//bazel:wit.bzl", "rust_wit_library", "wasm_component")
load("@rules_rust//rust:defs.bzl", "rust_library", "rust_shared_library")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

copy_file(
    name = "wasi-snapshot-preview1-proxy",
    visibility = ["//visibility:public"],
    src = "@wasi-snapshot-preview1-proxy//file",
    out = "wasi_snapshot_preview1.wasm",
)

rust_wit_library(
    name = "bindings",
    wit = "@wasi-http//:wasi-http",
    world = "proxy",
    crate_name = "bindings",
)

rust_shared_library(
    name = "proxy.wasm",
    srcs = ["lib.rs"],
    deps = [
        ":bindings",
        "@crates//:wit-bindgen-rt",
        "//cabi-realloc",
    ],
    crate_name = "proxy",
    platform = "@rules_rust//rust/platform:wasi",
)

wasm_component(
    name = "proxy.component.wasm",
    module = ":proxy.wasm",
    wit = "@wasi-http//:wasi-http",
    world = "proxy",
    adapter = ":wasi-snapshot-preview1-proxy",
)
