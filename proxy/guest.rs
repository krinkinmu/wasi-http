// This module contains declaration of guest functions that we are expected
// turing the lifecycle of plugin/request/response handling.
use crate::types::c_types::{
    FilterHeadersStatus,
    FilterDataStatus,
    FilterTrailersStatus,
};

extern "C" {

pub fn proxy_on_context_create(context_id: u32, parent_context_id: u32);
pub fn proxy_on_request_headers(context_id: u32, headers: u32, end_of_stream: u32) -> FilterHeadersStatus;
pub fn proxy_on_request_body(context_id: u32, body_buffer_length: u32, end_of_stream: u32) -> FilterDataStatus;
pub fn proxy_on_request_trailers(context_id: u32, trailers: u32) -> FilterTrailersStatus;
pub fn proxy_on_response_headers(context_id: u32, headers: u32, end_of_stream: u32) -> FilterHeadersStatus;
pub fn proxy_on_response_body(context_id: u32, body_buffer_length: u32, end_of_stream: u32) -> FilterDataStatus;
pub fn proxy_on_response_trailers(context_id: u32, trailers: u32) -> FilterHeadersStatus;

}
