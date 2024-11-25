#!/usr/bib/env bash

wit-deps lock && \
wit-bindgen c wit --out-dir=src && \
make && \
wasmtime serve handle-component.wasm
