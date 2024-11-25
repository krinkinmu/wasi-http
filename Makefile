all: handle-component.wasm

handle.wasm:
	docker run -v ./src:/src -w /src ghcr.io/webassembly/wasi-sdk make
	cp src/handle.wasm handle.wasm

wasi_snapshot_preview1.wasm:
	wget https://github.com/bytecodealliance/wasmtime/releases/download/v17.0.0/wasi_snapshot_preview1.proxy.wasm -O wasi_snapshot_preview1.wasm

handle-component.wasm: handle.wasm wasi_snapshot_preview1.wasm
	wasm-tools component new handle.wasm --adapt wasi_snapshot_preview1.wasm -o handle-component.wasm
