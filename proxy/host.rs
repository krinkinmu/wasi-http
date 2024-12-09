// This module contains the implementation of the proxy-wasm host calls (e.g.,
// requests that a proxy-wasm guest module/plugin can make to the host.
use bindings::wasi::cli::stdout::get_stdout;
use bindings::wasi::cli::stderr::get_stderr;
use crate::types::c_types;
use crate::types::{LogLevel, WasmResult};

// It looks like wasi-logging proposal exists in principle (see
// https://github.com/WebAssembly/wasi-logging), so in principle in the future,
// hypothetically, we could just rely on wasi-logging component instead.
//
// For now, however, I chose to just use whatever tools are available to me now
// from the proxy world, legacy interfaces and non-WASI external functions.
#[no_mangle]
pub extern "C" fn proxy_log(level: c_types::LogLevel,
             message: *const c_types::c_char,
             message_size: c_types::c_size_t) -> c_types::WasmResult {
    let message = unsafe {
        std::slice::from_raw_parts(message as *const u8, message_size as usize)
    };
    match level.try_into() {
    Ok(LogLevel::Trace) | Ok(LogLevel::Debug) | Ok(LogLevel::Info) => {
        let stdout = get_stdout();
        stdout.blocking_write_and_flush(message).unwrap();
    },
    Ok(LogLevel::Warn) | Ok(LogLevel::Err) | Ok(LogLevel::Critical) => {
        let stderr = get_stderr();
        stderr.blocking_write_and_flush(message).unwrap();
    }
    _ => return WasmResult::BadArgument.into(),
    };
    WasmResult::Ok.into()
}

#[no_mangle]
pub extern "C" fn proxy_get_log_level(level: *mut c_types::LogLevel) -> c_types::WasmResult {
    unsafe {
        *level = LogLevel::Trace.into()
    };
    WasmResult::Ok.into()
}

#[no_mangle]
pub extern "C" fn proxy_get_property(
        path: *const c_types::c_char, path_size: c_types::c_size_t,
        result: *mut *const c_types::c_char, result_size: *mut c_types::c_size_t) -> c_types::WasmResult {
    let root_id: &'static str = "";

    let key = std::str::from_utf8(unsafe {
        std::slice::from_raw_parts(path as *const u8, path_size as usize)
    }).unwrap();
    if key == "plugin_root_id" {
        unsafe {
            let bytes = root_id.as_bytes();
            *result = bytes.as_ptr() as *const c_types::c_char;
            *result_size = bytes.len() as c_types::c_size_t;
        };
        WasmResult::Ok.into()
    } else {
        WasmResult::NotFound.into()
    }
}
