// This module contains the implementation of the proxy-wasm host calls (e.g.,
// requests that a proxy-wasm guest module/plugin can make to the host.
use std::convert::{TryFrom, Into};

pub mod c_types {
    pub type WasmResult = u32;
    pub type LogLevel = i32;
    // Rust does not provide C size_t type outside of experimental yet.
    // Follow tracking issue https://github.com/rust-lang/rust/issues/88345.
    pub type CSize = usize;
    pub type CChar = std::ffi::c_char;

    pub type FilterHeadersStatus = i32;
    pub type FilterDataStatus = i32;
    pub type FilterTrailersStatus = i32;
}

pub enum WasmResult {
    Ok = 0,
    NotFound = 1,
    BadArgument = 2,
    SerializationFailure = 3,
    ParseFailure = 4,
    BadExpression = 5,
    InvalidMemoryAccess = 6,
    Empty = 7,
    CasMismatch = 8,
    ResultMismatch = 9,
    InternalFailure = 10,
    BrokenConnection = 11,
    Unimplemented = 12,
}

impl TryFrom<c_types::WasmResult> for WasmResult {
    type Error = ();

    fn try_from(r: c_types::WasmResult) -> Result<Self, Self::Error> {
        match r {
        0 => Ok(WasmResult::Ok),
        1 => Ok(WasmResult::NotFound),
        2 => Ok(WasmResult::BadArgument),
        3 => Ok(WasmResult::SerializationFailure),
        4 => Ok(WasmResult::ParseFailure),
        5 => Ok(WasmResult::BadExpression),
        6 => Ok(WasmResult::InvalidMemoryAccess),
        7 => Ok(WasmResult::Empty),
        8 => Ok(WasmResult::CasMismatch),
        9 => Ok(WasmResult::ResultMismatch),
        10 => Ok(WasmResult::InternalFailure),
        11 => Ok(WasmResult::BrokenConnection),
        12 => Ok(WasmResult::Unimplemented),
        _ => Err(()),
        }
    }
}

impl Into<c_types::WasmResult> for WasmResult {

    fn into(self) -> c_types::WasmResult {
        self as c_types::WasmResult
    }
}

pub enum LogLevel {
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warn = 3,
    Err = 4,
    Critical = 5,
}

impl TryFrom<c_types::LogLevel> for LogLevel {
    type Error = ();

    fn try_from(l: c_types::LogLevel) -> Result<Self, Self::Error> {
        match l {
        0 => Ok(LogLevel::Trace),
        1 => Ok(LogLevel::Debug),
        2 => Ok(LogLevel::Info),
        3 => Ok(LogLevel::Warn),
        4 => Ok(LogLevel::Err),
        5 => Ok(LogLevel::Critical),
        _ => Err(()),
        }
    }
}

impl Into<c_types::LogLevel> for LogLevel {
    fn into(self) -> c_types::LogLevel {
        self as c_types::LogLevel
    }
}

