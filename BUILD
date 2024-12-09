load("//bazel:wit.bzl", "wasm_component")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

cc_binary(
    name = "example.wasm",
    srcs = ["example.cc"],
    linkopts = [
        "-mexec-model=reactor",
        "-Wl,--export=wasi:http/incoming-handler@0.2.2#handle",
    ],
    deps = [
        "//proxy-wasm-cpp-sdk:proxy-wasm",
        "//proxy:proxy",
    ],
)

copy_file(
    name = "wasi-snapshot-preview1-proxy",
    visibility = ["//visibility:public"],
    src = "@wasi-snapshot-preview1-proxy//file",
    out = "wasi_snapshot_preview1.wasm",
)

wasm_component(
    name = "example.component.wasm",
    module = ":example.wasm",
    wit = "@wasi-http//:wasi-http",
    world = "proxy",
    adapter = ":wasi-snapshot-preview1-proxy",
)

