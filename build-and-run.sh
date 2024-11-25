#!/usr/bib/env bash

wit-deps lock && \
cargo component build --release && \
wasmtime serve target/wasm32-wasip1/release/http_proxy.wasm 
