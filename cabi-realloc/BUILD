load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

# Generate a name that Rust wit-bindgen expects
copy_file(
    name = "libcabi-realloc",
    src = "@wit-bindgen-cabi-realloc//file",
    out = "libwit_bindgen_cabi_realloc0_0_0.a",
)

cc_import(
    name = "cabi-realloc",
    visibility = ["//visibility:public"],
    static_library = ":libcabi-realloc",
)
