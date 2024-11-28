load(":toolchain.bzl", "wasm32_wasi_toolchain_config");

# Refer to https://bazel.build/tutorials/ccp-toolchain-config for the
# explanation of steps involved in defining a new toolchain.
filegroup(name = "empty")

platform(
    name = "wasip1",
    constraint_values = [
        "@platforms//cpu:wasm32",
        "@platforms//os:wasi",
    ],
)

wasm32_wasi_toolchain_config(name = "wasm32-wasi-cc-toolchain-config")

cc_toolchain(
    name = "wasm32-wasi-cc-toolchain",
    toolchain_config = ":wasm32-wasi-cc-toolchain-config",
    all_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = False,
)

toolchain(
    name = "wasm32-wasi-toolchain",
    toolchain = ":wasm32-wasi-cc-toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    target_compatible_with = [
        "@platforms//cpu:wasm32",
        "@platforms//os:wasi",
    ],
)
