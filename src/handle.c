#include "target.h"

void exports_wasi_http_incoming_handler_handle(
    exports_wasi_http_incoming_handler_own_incoming_request_t request,
    exports_wasi_http_incoming_handler_own_response_outparam_t response_out) {
  wasi_http_types_result_own_outgoing_response_error_code_t response;
  response.is_err = true;
  response.val.err.tag = WASI_HTTP_TYPES_ERROR_CODE_INTERNAL_ERROR;
  response.val.err.val.internal_error.is_some = true;
  target_string_set(&response.val.err.val.internal_error.val, "an error");
  wasi_http_types_static_response_outparam_set(response_out, &response);
}
