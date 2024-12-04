#!/usr/bin/env python3
import argparse
import pathlib
import shutil
import sys

def copy_dir(source, target):
    shutil.rmtree(target, ignore_errors=True)
    target.mkdir()

    for file in source.glob('*.wit'):
        print(file)
        name = file.name
        path = target.joinpath(name)
        shutil.copyfile(file, path)

def run(args: argparse.Namespace):
    root, deps = args.package, args.package.joinpath('deps')
    shutil.rmtree(root, ignore_errors=True)
    root.mkdir()
    deps.mkdir()

    for source in args.sources:
        name = source.name
        target = root.joinpath(name)
        shutil.copyfile(source, target)

    for dependency in args.with_dependencies:
        name = dependency.name
        target = deps.joinpath(name)
        copy_dir(dependency, target)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='wit-package')
    parser.add_argument(
        'sources', nargs='+', type=pathlib.Path,
        help='List of WIT files that make up the package',
        metavar='<wit file>')
    parser.add_argument(
        '--package', required=True, type=pathlib.Path,
        help='Directory where the result will be produced.',
        metavar='<output wit package dir>')
    parser.add_argument(
        '--with_dependencies', nargs='*', type=pathlib.Path,
        help='List of directories containing WIT packages this one depends on.',
        metavar='<wit package dir>')
    run(parser.parse_args())
