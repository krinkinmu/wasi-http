// Copyright 2016-2020 Envoy Project Authors
// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <string>
#include <string_view>
#include <unordered_map>

#include "proxy-wasm-cpp-sdk/proxy_wasm_intrinsics.h"

class ExampleRootContext : public RootContext {
public:
  explicit ExampleRootContext(uint32_t id, std::string_view root_id)
    : RootContext(id, root_id) {}

  bool onStart(size_t) override {
    logDebug("RootContext::onStart()");
    return true;
  }

  bool onDone() override {
    logDebug("RootContext::onDone()");
    return true;
  }

  void onCreate() override {
    logDebug("RootContext::onCreate()");
  }
};

class ExampleContext : public Context {
public:
  explicit ExampleContext(uint32_t id, RootContext *root) : Context(id, root) {}

  void onCreate() override {
    logDebug("Context::onCreate");
  }

  void onDone() override {
    logDebug("Context::onDone");
  }

  FilterMetadataStatus onRequestMetadata(uint32_t) override {
    logDebug("Context::onRequestMetadata");
    return FilterMetadataStatus::Continue;
  }

  FilterHeadersStatus onRequestHeaders(uint32_t, bool) override {
    logDebug("Context::onRequestHeaders");
    return FilterHeadersStatus::Continue;
  }

  FilterDataStatus onRequestBody(size_t, bool) override {
    logDebug("Context::onRequestBody");
    return FilterDataStatus::Continue;
  }

  FilterTrailersStatus onRequestTrailers(uint32_t) override {
    logDebug("Context::onRequestTrailers");
    return FilterTrailersStatus::Continue;
  }

  FilterMetadataStatus onResponseMetadata(uint32_t) override {
    logDebug("Context::onResponseMetadata");
    return FilterMetadataStatus::Continue;
  }

  FilterHeadersStatus onResponseHeaders(uint32_t, bool) override {
    logDebug("Context::onResponseHeaders");
    return FilterHeadersStatus::Continue;
  }

  FilterDataStatus onResponseBody(size_t, bool) override {
    logDebug("Context::onResponseBody");
    return FilterDataStatus::Continue;
  }

  FilterTrailersStatus onResponseTrailers(uint32_t) override {
    logDebug("Context::onResponseTrailers");
    return FilterTrailersStatus::Continue;
  }
};

static RegisterContextFactory register_ExampleContext(
  CONTEXT_FACTORY(ExampleContext), ROOT_FACTORY(ExampleRootContext));

