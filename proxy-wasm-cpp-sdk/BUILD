filegroup(
    name = "imported-functions",
    srcs = ["imported-functions.txt"],
)

cc_library(
    name = "proxy-wasm",
    visibility = [
        "//visibility:public",
    ],
    copts = [
        "-fno-exceptions",
    ],
    linkopts = [
        "-Wl,--allow-undefined-file=$(location :imported-functions)",
        "-Wl,--export=malloc",
    ],
    srcs = [
        "proxy_wasm_intrinsics.cc",
    ],
    hdrs = [
        "proxy_wasm_api.h",
        "proxy_wasm_common.h",
        "proxy_wasm_enums.h",
        "proxy_wasm_externs.h",
        "proxy_wasm_intrinsics.h",
    ],
    additional_linker_inputs = [
        ":imported-functions",
    ],
)
