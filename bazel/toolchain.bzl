load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "feature", "flag_set", "flag_group", "tool_path")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

COMPILE_ACTIONS = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.c_compile,
]

LINK_ACTIONS = [
    ACTION_NAMES.cpp_link_executable,
]

COMPILE_AND_LINK_ACTIONS = COMPILE_ACTIONS + LINK_ACTIONS

target_wasm32 = feature(
    name = "target-wasm32",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = COMPILE_AND_LINK_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = ["--target=wasm32"],
                ),
            ],
        )
    ],
)

nostdlib = feature(
    name = "nostdlib",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = COMPILE_AND_LINK_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = ["-nostdlib"],
                ),
            ],
        ),
    ],
)

no_entry = feature(
    name = "no-entry",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = LINK_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = ["-Wl,--no-entry"],
                ),
            ],
        ),
    ],
)

export_all = feature(
    name = "export-all",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = LINK_ACTIONS,
            flag_groups = [
                flag_group(
                    flags = ["-Wl,--export-all", "-Wl,--no-gc-sections"],
                ),
            ],
        ),
    ],
)

def _toolchain_config_impl(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "wasm32-wasi",
        target_system_name = "wasm32-wasi",
        target_cpu = "wasm32",
        target_libc = "wasi",
        compiler = "clang",
        # This seem to be the only thing that matters in the rule, all the
        # values above, I think, ignored in the ne enough versions of Bazel. 
        tool_paths = [
            tool_path(
                name = "gcc",
                path = "/usr/bin/clang",
            ),
            tool_path(
                name = "ar",
                path = "/usr/bin/llvm-ar",
            ),
            tool_path(
                name = "ld",
                path = "/bin/false",
            ),
            tool_path(
                name = "cpp",
                path = "/bin/false",
            ),
            tool_path(
                name = "nm",
                path = "/bin/false",
            ),
            tool_path(
                name = "objdump",
                path = "/bin/false",
            ),
            tool_path(
                name = "strip",
                path = "/bin/false",
            ),
        ],
        features = [
            target_wasm32,
            export_all,
            no_entry,
            nostdlib,
        ],
    )

wasm32_wasi_toolchain_config = rule(
    implementation = _toolchain_config_impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)
