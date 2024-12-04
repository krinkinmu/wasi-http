load("@rules_rust//rust:defs.bzl", "rust_library")

# We basically want to do a Bazel version of wit-deps tool that can put all
# WASI components together in a way that wit-bindgen can use. The difference
# is that unlike wit-deps we will not download the components directly and
# instead let users to describe all the WIT packages as Bazel rules and
# download what they need (if they need to download anything) using regular
# Bazel tools (e.g., http_archive).
#
# In order to satisfy wit-bindgen what we need is to create a directory
# structure that looks something like this:
#
# <top-level-dir>/
#  +- a.wit
#  |
#  +- b.wit
#  |
#  +- deps/
#   +- dep1/
#   |+- dep1.wit
#   +- dep2.wit
#
# We might have some top-level definitions (e.g., a.wit and b.wit in the
# directory tree above) and a directory with dependencies. The directory with
# dependencies contains components directory required by top level definitions
# and their transitive dependencies (e.g., in the example above dep1 might be
# required by a.wit and dep2 might be required by dep1, but both dep1 and dep2
# will be at the same level in the deps directory).
#
# In bazel we want to describe each wit package using wit_package rule that is
# defined here. Linking the rules together via deps, just like it's done, for
# example, for C++ libraries using cc_library we can figure out what WIT
# packages depend on each other.
#
# Once we encode all the dependencies between WIT packages via Bazel rules,
# to actually use WIT packages to generate bindings we just need to put them
# on the filesystem in the right way (creating a structure similar to the above
# ) and call wit-bindgen giving it the path to this directory.

# WitPackageInfo is a Bazel provider (see
# https://docs.bazel.build/versions/4.1.0/skylark/rules.html#providers) that
# keeps track of the dependencies of WIT package and the name of the package.
#
# NOTE: Naming Bazel providers like *Info is a comon convention used in Bazel
# apparently.
WitPackageInfo = provider(
    "WIT package",
    fields = {
        "deps": "all dependencies of this WIT package, direct or indirect.",
    },
)

def _wit_package_impl(ctx):
    # This rule is what actually constructs a directory structure that
    # wit-bindgen expects. So the artifact produced as a result of executing
    # this rule is a directory with files that describe WIT package as well
    # as dependency WIT packages.

    name = ctx.label.name
    directory = ctx.actions.declare_directory(name)
    # We combine the direct dependencies with transitive dependencies.
    #
    # ctx.files.deps points to the direct dependencies (or more specifically
    # directories that contain definitions of WIT packages we depend on directly
    # as provided by the DefaultInfo).
    #
    # WitPackageInfo.deps is used to aggregate all the indirect dependencies
    # (or again, list of the directories with the indirect dependencies).
    deps = depset(
        ctx.files.deps,
        transitive = [
            dep[WitPackageInfo].deps for dep in ctx.attr.deps
            if WitPackageInfo in dep
        ],
    )
    all_deps = deps.to_list()

    # We declared directory that is the main artifact of executing this rule,
    # now we need to create the directory with all its content by running the
    # packaging tool.
    ctx.actions.run(
        inputs = ctx.files.srcs + all_deps,
        outputs = [directory],
        executable = ctx.executable.packager,
        arguments = [
            src.path for src in ctx.files.srcs
        ] + [
            "--package",
            directory.path,
            "--with_dependencies",
        ] + [
            dep.path for dep in all_deps
        ],
    )

    return [
        # When we "build" this rule, the artifact is the directory with some
        # files in it, that's why we specify it as the value for the "files"
        # attribute in DefaultInfo.
        #
        # NOTE: Despite the name, files does not actually mean files, it can
        # also mean directories in Bazel.
        DefaultInfo(files = depset([directory])),

        # To be able to pull in all the dependencies (including transitive) into
        # the final deps folder, we need to list them somehow. WitPackageInfo
        # is used to keep track of the dependencies.
        WitPackageInfo(deps = deps),
    ]


wit_package = rule(
    implementation = _wit_package_impl,
    doc =
        "Collection of files that make up a WIT package, plus a list of " +
        "required dependencies.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".wit"],
            mandatory = True,
        ),
        "deps": attr.label_list(
            providers = [WitPackageInfo],
        ),
        "packager": attr.label(
            default = "@//tools:wit-package",
            cfg = "exec",
            executable = True,
        ),
    },
    provides = [WitPackageInfo],
)

