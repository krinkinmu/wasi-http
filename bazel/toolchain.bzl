load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "feature", "flag_set", "flag_group", "variable_with_value", "action_config")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

COMPILE_ACTIONS = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_header_parsing,
]

LINK_ACTIONS = [
    ACTION_NAMES.cpp_link_executable,
]

COMPILE_AND_LINK_ACTIONS = COMPILE_ACTIONS + LINK_ACTIONS

# I didn't find a simple enough way to provide a path to a directory as
# a target/label, so I am hardcoding the path to the directory with header
# files explicitly here.
wasm32_wasip1_headers = feature(
    name = "wasm32-wasip1-headers",
    enabled = False,
    flag_sets = [
        flag_set(
            actions = COMPILE_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = [
                        "-isystem", "external/_main~_repo_rules~wasi-sdk/share/wasi-sysroot/include/wasm32-wasip1/c++/v1",
                        "-isystem", "external/_main~_repo_rules~wasi-sdk/share/wasi-sysroot/include/wasm32-wasip1",
                        "-isystem", "external/_main~_repo_rules~wasi-sdk/lib/clang/18/include",
                    ],
                ),
            ],
        )
    ],
)

# Similarly to the header files above, I'm hardcoding the path to the
# directory with libs as well.
wasm32_wasip1_libs = feature(
    name = "wasm32-wasip1-libs",
    enabled = False,
    flag_sets = [
        flag_set(
            actions = LINK_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = [
                        "-L", "external/_main~_repo_rules~wasi-sdk/share/wasi-sysroot/lib/wasm32-wasip1",
                    ],
                ),
            ],
        )
    ],
)

target_wasm32_wasip1 = feature(
    name = "target-wasm32-wasip1",
    enabled = True,
    # This feature automatically enables features that provide header and lib
    # paths for --target=wasm32-wasip1.
    implies = [
        "wasm32-wasip1-headers",
        "wasm32-wasip1-libs",
    ],
    # This feature is mutually exclusive with other targets.
    provides = ["target"],
    flag_sets = [
        flag_set(
            actions = COMPILE_AND_LINK_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = [
                        "-target", "wasm32-wasip1",
                    ],
                ),
            ],
        )
    ],
)

default_libs = feature(
    name = "default-libs",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = LINK_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = [
                        "-l:libc++.a",
                        "-l:libc++abi.a",
                    ],
                ),
            ],
        ),
    ],
)

archiver_flags = feature(
    name = "archiver_flags",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = [ACTION_NAMES.cpp_link_static_library],
            flag_groups = [
                flag_group(flags = ["rcsD"]),
                flag_group(
                    flags = ["%{output_execpath}"],
                    expand_if_available = "output_execpath",
                ),
                flag_group(
                    iterate_over = "libraries_to_link",
                    expand_if_available = "libraries_to_link",
                    flag_groups = [
                        flag_group(
                            flags = ["%{libraries_to_link.name}"],
                            expand_if_equal = variable_with_value(
                                name = "libraries_to_link.type",
                                value = "object_file",
                            ),
                        ),
                        flag_group(
                            flags = ["%{libraries_to_link.object_files}"],
                            iterate_over = "libraries_to_link.object_files",
                            expand_if_equal = variable_with_value(
                                name = "libraries_to_link.type",
                                value = "object_file_group",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    ],
)

supports_start_end_lib = feature(
    name = "supports_start_end_lib",
    enabled = True,
)

no_exceptions = feature(
    name = "no-exceptions",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = COMPILE_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = ["-fno-exceptions"],
                ),
            ],
        ),
    ],
)

debug_info = feature(
    name = "debug-info",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = COMPILE_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = ["-g"],
                ),
            ],
        ),
    ],
)

def _toolchain_config_impl(ctx):
    cc_compile_action = action_config(
        action_name = ACTION_NAMES.cpp_compile,
        tools = [
            struct(
                type_name = "tool",
                tool = ctx.file.compiler,
            ),
        ],
    )
    c_compile_action = action_config(
        action_name = ACTION_NAMES.c_compile,
        tools = [
            struct(
                type_name = "tool",
                tool = ctx.file.compiler,
            ),
        ],
    )
    cc_link_binary_action = action_config(
        action_name = ACTION_NAMES.cpp_link_executable,
        tools = [
            struct(
                type_name = "tool",
                tool = ctx.file.compiler,
            ),
        ],
    )
    archive_action = action_config(
        action_name = ACTION_NAMES.cpp_link_static_library,
        tools = [
            struct(
                type_name = "tool",
                tool = ctx.file.archiver,
            ),
        ]
    )

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "wasm32-wasi",
        target_system_name = "wasm32-wasi",
        target_cpu = "wasm32",
        target_libc = "wasi",
        compiler = "clang",
        action_configs = [
            c_compile_action,
            cc_compile_action,
            archive_action,
            cc_link_binary_action,
        ],
        features = [
            wasm32_wasip1_headers,
            wasm32_wasip1_libs,
            target_wasm32_wasip1,
            default_libs,
            archiver_flags,
            supports_start_end_lib,
            no_exceptions,
            debug_info,
        ],
    )

wasm32_wasi_toolchain_config = rule(
    implementation = _toolchain_config_impl,
    attrs = {
        "compiler": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "archiver": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
    },
    provides = [CcToolchainConfigInfo],
)
