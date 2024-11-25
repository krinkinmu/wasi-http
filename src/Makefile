CC ?= clang

all: handle.wasm

handle.wasm: target.c target.h handle.c target_component_type.o
	$(CC) target.c handle.c target_component_type.o -o handle.wasm -mexec-model=reactor
