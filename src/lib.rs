#[allow(warnings)]
mod bindings;

use bindings::exports::wasi::http::incoming_handler::Guest;
use bindings::wasi::http::types::{
    Fields, IncomingRequest, OutgoingBody, OutgoingResponse, ResponseOutparam,
};

struct Component;

impl Guest for Component {
    fn handle(_request: IncomingRequest, response: ResponseOutparam) {
        let hdrs = Fields::new();
        let resp = OutgoingResponse::new(hdrs);
        let body = resp.body().expect("outgoing response");
        {
            let out = body.write().expect("outgoing stream");
            out.blocking_write_and_flush(b"OK\n").expect("writing response");
        }
        OutgoingBody::finish(body, None).unwrap();
        ResponseOutparam::set(response, Ok(resp));
    }
}

bindings::export!(Component with_types_in bindings);
