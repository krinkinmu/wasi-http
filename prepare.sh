#!/usr/bin/env bash

cargo install wasm-tools
cargo install wit-bindgen-cli
cargo install wit-deps
cargo install cargo-component
curl https://wasmtime.dev/install.sh -sSf | bash
