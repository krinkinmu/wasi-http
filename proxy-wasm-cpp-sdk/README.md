# proxy-wasm C++ SDK

This is a partial copy of the proxy-wasm C++ SDK taken from
https://github.com/proxy-wasm/proxy-wasm-cpp-sdk at the a982ad089d1962f1b92f4343c910c0be6b6e6280
commit.

I didn't figure out yet how to properly include it into my future solution (partially because I
haven't figured out what the final solution will look like in the first place), so I'm just copying
the relevant parts into this repository for now and apply a few modifications.

The only not original files in this directory are this `README.md`, `BUILD` file and
`imported-functions.txt` - those were not copied from the original C++ SDK.

I need a different `BUILD`file because I use different toolchain compared to C++ SDK (they use
Emscripten, while I rely on wasi-sdk). `imported-functions.txt` is an equivalent of the
`proxy_wasm_intrinsics.js` in the original SDK, but it's consumed by the wasm linker that comes with
wasi-sdk and follows the required format.

Additionally, I got rid of `PROXY_WASM_KEEPALIVE` macro in favor of using `WASM_EXPORT`.
`WASM_EXPORT` was modified to explicitly set `export_name` attribute on the symbols that we need to
be exported by the binary (see https://lld.llvm.org/WebAssembly.html#exports for the details).
