load("//bazel:wit.bzl", "rust_wit_library")
load("@rules_rust//rust:defs.bzl", "rust_library")

rust_wit_library(
    name = "bindings",
    wit = "@wasi-http//:wasi-http",
    world = "proxy",
    crate_name = "bindings",
)

rust_library(
    name = "proxy_impl",
    srcs = [
        "lib.rs",
        "types.rs",
        "host.rs",
        "guest.rs",
        "alloc.rs",
    ],
    deps = [
        ":bindings",
        "@crates//:wit-bindgen-rt",
        "//cabi-realloc",
    ],
    crate_name = "proxy",
)

cc_import(
    name = "proxy",
    visibility = ["//visibility:public"],
    deps = [":proxy_impl"],
    linkopts = [
        "-Wl,--export=wasi:http/incoming-handler@0.2.2#handle",
    ],
)
