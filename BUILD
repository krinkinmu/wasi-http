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
