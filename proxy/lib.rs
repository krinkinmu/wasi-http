extern crate bindings;

mod alloc;
mod host;
mod guest;
mod types;

use bindings::exports::wasi::http::incoming_handler::Guest;
use bindings::wasi::http::outgoing_handler::handle as send_request;
use bindings::wasi::http::types::{
    IncomingRequest,
    OutgoingRequest,
    OutgoingResponse,
    ResponseOutparam,
    InputStream,
    OutputStream,
    IncomingBody,
    OutgoingBody,
};
use bindings::wasi::io::streams::StreamError;

struct Proxy;

// As a hack, I expect the incoming request headers to actually tell us where
// the request should be forwarded (after modifying it using proxy-wasm plugin
// ). Real proxies naturally would have the proper configuration and will be
// able to figure out where the request should be sent and we would not need
// this hack.
fn request_target(request: &IncomingRequest) -> String {
    let headers = request.headers();
    let targets = headers.get(&"destination".to_string());
    assert!(
        targets.len() == 1,
        "'destination' header is expected to have exactly one value");
    String::from_utf8(targets.first().unwrap().to_vec())
        .expect("'destination' header must be a valid HTTP authority")
}

fn stream_data(request: bool, end_of_stream: bool, source: &InputStream, destination: &OutputStream) {
    // TODO: It's a bit too simplistic at the moment in the sense, that real
    // proxies should be able to do some non-trivial buffering. For example,
    // in Envoy it's possible to write a plugin that will look at the body and
    // even trailers, and based on that information nmodify some headers.
    //
    // Proxy-wasm does not currently support this type of buffering due to
    // various reasons (starting from just complexity and ending with the
    // fact that such buffering does not scale very well and is of limited
    // use). Regardless, because Envoy supports it, I'd imagine it could change
    // and there are definitely use cases for this,
    //
    // So I need to decople bits and pieces more, so that we could start
    // processing the body and trailers before we actually finished processing
    // headers. Maybe we would even need some event loop implementation
    // alongside the buffering implementation as well.
    loop {
        let source_ready = source.subscribe();
        source_ready.block();

        let destination_ready = destination.subscribe();
        destination_ready.block();

        // Now we have some data in the source to read (or encountered an error
        // ) and the destination is ready to accept the data (or encountered an
        // error). So let's copy as much data as we can using non-blocking API.

        let buffer = match destination.check_write() {
            Ok(allowed) => allowed,
            Err(_) => panic!("Destination closed connection prematurely"),
        };
 
        match source.read(buffer) {
            Ok(data) => {
                // TODO: modify data here
                if request {
                    unsafe {
                        guest::proxy_on_request_body(
                            2, data.len() as u32, end_of_stream as u32);
                    }
                } else {
                    unsafe {
                        guest::proxy_on_response_body(
                            2, data.len() as u32, end_of_stream as u32);
                    }
                }
                destination.write(&data[..]).unwrap();
            },
            Err(StreamError::Closed) => {
                // We are done, so flush all the data we wrote and return.
                destination.flush().unwrap();
                return;
            },
            Err(_) => {
                panic!("Encountered an error when reading the body of the incoming request");
            },
        }
    }
}

impl Guest for Proxy {
    // TODO:
    // -- I need to figure out how exactly does Envoy propagate end_of_stream
    //    flag across different calls and how accurate that information is
    // -- Support asynchronous APIs and pausing processing from the proxy-wasm
    //    plugin (e.g., when they return StopIteration)
    // -- [Maybe] have an even loop architecture for easier async logic
    // -- [Maybe] have buffering
    fn handle(request: IncomingRequest, out: ResponseOutparam) {
        // I think, and I need to double check that, proxy-wasm has basically
        // 2 different types of contexts:
        //
        //   - Root context, which I think, is created for each worker thread
        //   - HTTP request/response context which is a chile of a root context
        //     and is created for each request/response
        //
        // I'm ignoring for now proxy-wasm TCP plugins and contexts associated
        // with TCP connections.
        //
        // I'm trying to simulate a similar setup here, so I create a root
        // context first and then a child request/response context.
        unsafe {
            guest::proxy_on_context_create(1, 0);
            guest::proxy_on_context_create(2, 1);
        }

        let authority = request_target(&request);
        let headers = request.headers().clone();

        let req = OutgoingRequest::new(headers);
        req.set_method(&request.method()).unwrap();
        req.set_path_with_query(request.path_with_query().as_deref()).unwrap();
        req.set_scheme(request.scheme().as_ref()).unwrap();
        req.set_authority(Some(authority.as_str())).unwrap();

        // TODO: modify headers here
        unsafe {
            guest::proxy_on_request_headers(
                2, req.headers().entries().len() as u32, /*end_of_stream=*/0);
        }

        let received_body = request.consume().unwrap();
        let sent_body = req.body().unwrap();

        // I'm not entirely sure here, but I assume that we can actually send
        // an HTTP reesponse before we finished constructing the body.
        // I assume it, because if it wasn't the case, it would force us to
        // construct the request completely before sending it and that would
        // not be a practical implementation (think very large requests).
        let future = send_request(req, None).unwrap();

        {
            let source = received_body.stream().unwrap();
            let destination = sent_body.write().unwrap();
            stream_data(
                /*request=*/true, /*end_of_stream*/false,
                &source, &destination);
        }

        {
            let future = IncomingBody::finish(received_body);
            future.subscribe().block();

            if let Some(trailers) = future.get().unwrap().unwrap().unwrap() {
                let trailers = trailers.clone();
                // TODO: modify trailers here
                unsafe {
                    guest::proxy_on_request_trailers(
                        2, trailers.entries().len() as u32);
                }
                OutgoingBody::finish(sent_body, Some(trailers)).unwrap();
            } else {
                OutgoingBody::finish(sent_body, None).unwrap();
            }
        }

        future.subscribe().block();
        let res = future.get().unwrap().unwrap().unwrap();

        let headers = res.headers().clone();
        let response = OutgoingResponse::new(headers);
        response.set_status_code(res.status()).unwrap();

        unsafe {
            guest::proxy_on_response_headers(
                2, response.headers().entries().len() as u32,
                /*end_of_stream*/0);
        }
        // TODO: modify response headers here

        let received_body = res.consume().unwrap();
        let sent_body = response.body().unwrap();

        // Just like above, here I assume that we can call this function before
        // we fully formed complete response, otherwise this would not be
        // practical. In this case though, an additional caveat is that I assume
        // that when I wrap the respone in Result::Ok it's not really an
        // indication that response is complete and successfull, though I don't
        // yet see a way to indicate an error after this point.
        ResponseOutparam::set(out, Ok(response));

        {
            let source = received_body.stream().unwrap();
            let destination = sent_body.write().unwrap();
            stream_data(
                /*request=*/false, /*end_of_stream=*/false,
                &source, &destination);
        }

        {
            let future = IncomingBody::finish(received_body);
            future.subscribe().block();

            if let Some(trailers) = future.get().unwrap().unwrap().unwrap() {
                let trailers = trailers.clone();
                // TODO: modufy response trailers here
                unsafe {
                    guest::proxy_on_response_trailers(
                        2, trailers.entries().len() as u32);
                }
                OutgoingBody::finish(sent_body, Some(trailers)).unwrap();
            } else {
                OutgoingBody::finish(sent_body, None).unwrap();
            }
        }
    }
}

bindings::export!(Proxy with_types_in bindings);
