#!/usr/bin/env bash

cargo install wasm-tools
cargo install wit-bindgen-cli
cargo install wit-deps
curl https://wasmtime.dev/install.sh -sSf | bash
