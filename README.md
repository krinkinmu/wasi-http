# proxy-wasm on wasi Explorations

## Building proxy-wasm on top of existing wasi components

It would be super nice if we could just implement proxy-wasm on top of the
existing wasi components and specifically wasi-http (and other components
could be used to provide utility services).

My thinking here was that if we can avoid introducing completely custom
interfaces, it would enable better re-use of code. I also personally was
hoping that we could potentially use wasmtime to test proxy-wasm modules
in isolation without using Envoy, by just running `wasmtime serve`.

That's what I started my exploration from, but predicatbly there are gaps
that prevent us from implementing proxy-wasm solely on top of existing
wasi components.

I'm listing some of the more obvious issues below.

### Sending HTTP requests to external services

My high-level idea is that a wasm HTTP plugin should implement
`incoming-handler` interface and in the implementation of the `handle`
function perform all the required manipulation on the HTTP request that
the proxy received.

Once we set up everything we need in the `handle` implementation the
plugin would call `outgoing-handler.handle` function to send the HTTP
request further down the filter chain and get the response.

Then the plugin would process the response, if needed, and return it
from the implementation of the `incoming-handler.handle` function.

> TL;DR implementation of `incoming-handler.handle` function would contain
> plugin business logic.

With that high level idea in mind, let's consider a plugin that needs to
call some external service before proxying a request/response (for the sake
of being specific, let's say it needs to call some caching service). A typical
way to call an external service would be HTTP request.

So we would need to different paths to send/receive HTTP requests/responses:

1. One of the proxied request/responses
2. Second one for the calls to external services

wasi-http doesn't provide us with other ways to make HTTP calls other than
`outgoing-handler.handle` and `incoming-handler.handle`, so those APIs will
have to be somehow overloaded for different purposes.

### Shared queues

Basically wasi does not have any existing interfaces that provides
functionality similar to shared queues.

## Approach

Given that we cannot implement full scope of proxy-wasm capabilities on top
of currently existing wasi components, we have a few options:

1. Propose new components to wasi to fill the gaps (for example, it's
   concivable that some kind of shared notification queues are of general
   use to the public and we could propose a component like that to wasi)
2. Defibe a proxy-wasm-like interface in WIT and move forward with that.

> NOTE: I don't think that we can define proxy-wasm interface in WIT exactly
> because WIT has some restrictions on naming, but we can define a functionally
> equivalent interface.

Going forward, I would like to re-use the existing wasi components where
possible (e.g. rely on wasi-http to send and receive HTTP requests), but fill
the gaps with the custom proxy-wasm-like component.

As for the backward compatibility with the existing proxy-wasm plugins, I'm
planning to implement a shim layer that would serve as a translation layer
between the legacy proxy-wasm and the component model version of proxy-wasm.

The shim layer will translate the component model calls into proxy-wasm ABI
calls and vice versa.

The reason why I want to work at the level of proxy-wasm ABI is that I want
the shim layer to be independent of the SDK language as much as practical, so
we can use the same shim for C++, Rust and Go proxy-wasm modules without 
changes to the shim or to the proxy-wasm modules. Based on my experiments
it should be feasible to do - essentially what we need is a moral equivalent
of null-vm host, but it has to work on the plugin side.

## Things to do

1. Define subset of the proxy-wasm interface in WIT;
   I would limit the work for now to just HTTP plugins, sending/receiving
   HTTP requests and timers
2. Have a proof-of-concept implementation of the component model for Envoy;
   I'm not completely sure what it would take to actually add support for
   components into proxy-wasm-cpp-host yet, hopefully it will just boil down
   to calling slightly differently named functions and maybe limiting the
   possible VMs to just `wasmtime`.
