// Unlike regular proxy-wasm host the shim layer lives in the same address
// space and uses the same allocator as the proxy-wasm guest. As a result we
// don't really need to call guest's malloc or proxy_on_allocate functions
// to reserve some memory in the guest - instead we can just allocate that
// memory directly.
//
// So directly allocating memory works, but what is the benefit of doing that?
// At the moment, C++ and Rust proxy-wasm SDK produce slightly different Wasm
// binaries. C++ SDK generates a binary with malloc function, while Rust SDK
// defines proxy_on_allocate instead. Both options are valid (though, malloc
// call is deprecated), but it creates a problem for the shim layer because
// it has to work with both Rust and C++ SDKs and somehow need to figure out
// what function to call. Allocating memory directly without calling a guest
// function, while isn't very precise, saves us a bit of trouble.
//
// NOTE: We can solve this problem in a few other ways:
//
// 1. We can fix the C++ SDK to expose proxy_on_allocate instead of malloc
// 2, We can compile-time configuration option that will control which
//    function we should call
// 3. Probably we can play with weak symbols and define implementations for
//    both proxy_on_allocate and malloc at the same time as long as we have
//    at least one of them defined.
//
// All those options are valid and still should be considered, but for now
// I opt-into a completely local option that will let me make progress for
// now, even if it's not the best. All other options, one way or another
// can be wrapped into this API, so that even if we switch to another solution
// in the future the callers of these functions should not be affected.
use std::mem::MaybeUninit;

pub fn allocate_in_guest(size: usize) -> *mut u8 {
    // Rust allocators work somewhat differently from C++/C  in some corner
    // cases. Specifically, Rust allocators, even when the allocated size is
    // 0, never return null. That would cause tons of confusion for the C/C++
    // code that may try to free memory allocated in Rust (and in fact,
    // proxy-wasm SDK does do that), because C/C++ code knows nothing about
    // the sentinel value used by Rust allocator and only treat null values
    // specially. That's why we have to work around this difference
    // explicitly.
    if size == 0 {
        return std::ptr::null_mut();
    }

    let mut buf: Vec<MaybeUninit<u8>> = Vec::with_capacity(size);
    // Once into_raw_parts is stable, we can probably switch to that. It should
    // be easier for the reader to belive that this code worls when memory
    // allocation APIs are symmetrical.
    buf.resize(size, MaybeUninit::uninit());
    Box::into_raw(buf.into_boxed_slice()) as *mut u8
}

// NOTE: in proxy-wasm we actually never need to deallocate anything on the
// host side, so this API is not really used, but I'm providing it nonetheless
// for symmetry, documentation and in case it will come in handy at some point.
#[allow(dead_code)]
pub fn deallocate_in_guest(ptr: *mut u8, size: usize) {
    if size == 0 || ptr == std::ptr::null_mut() {
        return;
    }
    unsafe { Vec::from_raw_parts(ptr, size, size) };
}
