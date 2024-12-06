load(":toolchain.bzl", "wasm32_wasi_toolchain_config")

# Refer to https://bazel.build/tutorials/ccp-toolchain-config for the
# explanation of steps involved in defining a new toolchain.
filegroup(name = "empty")

# These are a signle file filegroups that just point to the clang binary
# and ar tool.
# We need them to pass to the toolchain configuration as a label and
# avoid hardcoding the paths to the tools.
filegroup(
    name = "clang",
    srcs = ["@wasi-sdk//:clang"]
)

filegroup(
    name = "ar",
    srcs = ["@wasi-sdk//:ar"]
)

filegroup(
    name = "clang-headers",
    srcs = ["@wasi-sdk//:headers"],
)

filegroup(
    name = "bin",
    srcs = ["@wasi-sdk//:bin"],
)

filegroup(
    name = "sysroot",
    srcs = ["@wasi-sdk//:sysroot"],
)

filegroup(
    name = "compiler-files",
    srcs = [
        ":sysroot",
        ":clang-headers",
        ":bin",
    ],
)

filegroup(
    name = "linker-files",
    srcs = [
        ":sysroot",
        ":bin",
    ],
)

filegroup(
    name = "archiver-files",
    srcs = [
        ":bin",
    ],
)

filegroup(
    name = "all-files",
    srcs = [
        ":compiler-files",
        ":linker-files",
        ":archiver-files",
    ],
)

platform(
    name = "wasi",
    constraint_values = [
        "@platforms//cpu:wasm32",
        "@platforms//os:wasi",
    ],
)

wasm32_wasi_toolchain_config(
    name = "wasm32-wasi-cc-toolchain-config",
    compiler = ":clang",
    archiver = ":ar",
)

cc_toolchain(
    name = "wasm32-wasi-cc-toolchain",
    toolchain_config = ":wasm32-wasi-cc-toolchain-config",
    all_files = ":all-files",
    ar_files = ":archiver-files",
    compiler_files = ":compiler-files",
    dwp_files = ":empty",
    linker_files = ":linker-files",
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
