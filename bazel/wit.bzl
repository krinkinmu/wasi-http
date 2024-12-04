load("@bazel_skylib//lib:paths.bzl", "paths")
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


def _to_rust_ident(world_name):
    # WIT identifiers must use so called "kebab-case" format - words seperated
    # by - characters. WIT identifiers can also have % at the beginning if it
    # conflicts with WIT keyword. Neither - nor % are allowed in Rust
    # identifiers.
    keywords = {
        "as": "as_",
        "break": "break_",
        "const": "const_",
        "continue": "continue_",
        "crate": "crate_",
        "else": "else_",
        "enum": "enum_",
        "extern": "extern_",
        "false": "false_",
        "fn": "fn_",
        "for": "for_",
        "if": "if_",
        "impl": "impl_",
        "in": "in_",
        "let": "let_",
        "loop": "loop_",
        "match": "match_",
        "mod": "mod_",
        "move": "move_",
        "mut": "mut_",
        "pub": "pub_",
        "ref": "ref_",
        "return": "return_",
        "self": "self_",
        "static": "static_",
        "struct": "struct_",
        "super": "super_",
        "trait": "trait_",
        "true": "true_",
        "type": "type_",
        "unsafe": "unsafe_",
        "use": "use_",
        "where": "where_",
        "while": "while_",
        "async": "async_",
        "await": "await_",
        "dyn": "dyn_",
        "abstract": "abstract_",
        "become": "become_",
        "box": "box_",
        "do": "do_",
        "final": "final_",
        "macro": "macro_",
        "override": "override_",
        "priv": "priv_",
        "typeof": "typeof_",
        "unsized": "unsized_",
        "virtual": "virtual_",
        "yield": "yield_",
        "try": "try_",
    }
    name = world_name.replace('%', '').replace('-', '_')
    return keywords.get(name) or name

def _rust_bindings_impl(ctx):
    # When it comes to Rust we basically want to produce a Rust lib crate.
    # In simple cases it could be just a single file and it looks like
    # in our case it should be good enough.
    #
    # As far as I understand, wit-bindgen basically generates a single
    # file for each WIT world, so calling wit-bindgen should only produce
    # a single Rust file.
    directory = paths.join(ctx.label.name, "rust_bindings")
    path = paths.join(directory, _to_rust_ident(ctx.attr.world) + ".rs") 
    bindings = ctx.actions.declare_file(path)
    ctx.actions.run(
        inputs = [ctx.file.wit],
        outputs = [bindings],
        executable = ctx.executable.bindgen,
        arguments = [
            "rust",
            ctx.file.wit.path,
            "--world",
            ctx.attr.world,
            "--out-dir",
            bindings.dirname,
            "--default-bindings-module",
            "bindings",
            # We want to be able to use the generate export macro in other
            # crates, so we have to make it public. I'm not entirely sure
            # why it's not the default behaviour to begin with.
            "--pub-export-macro",
            # Generate all the interfaces, since we don't really know in this
            # rule (and we probably shouldn't care), which interfaces are
            # going to be used by the final module.
            "--generate-all",
        ],
    )
    return [DefaultInfo(files = depset([bindings]))]
    

rust_bindings = rule(
    implementation = _rust_bindings_impl,
    doc = "Calls wit-bindgen to generate Rust bindings for the WIT package.",
    attrs = {
        "wit": attr.label(
            doc = "WIT package to produce bindings for.",
            allow_single_file = True,
            mandatory = True,
            providers = [WitPackageInfo],
        ),
        "world": attr.string(
            doc = "World to generate Rust bindings for",
            mandatory = True,
        ),
        "lib_template": attr.label(
            default = ":lib-rs-template",
            allow_single_file = True,
        ),
        "bindgen": attr.label(
            default = "@wit-bindgen-cli//:wit-bindgen-cli",
            executable = True,
            cfg = "exec",
        ),
    },
)

def rust_wit_library(name, wit, world, crate_name = None, **kwargs):
    rust_bindings(
        name = name + "_bindings",
        wit = wit,
        world = world,
        **kwargs,
    )
    rust_library(
        name = name,
        srcs = [":" + name + "_bindings"],
        deps = ["@crates//:wit-bindgen"],
        crate_name = crate_name,
    )
