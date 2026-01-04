module restful

import net.http

pub interface Backend {
	do(req RequestConfig) !Response
}

pub struct RequestConfig {
pub:
	method  string
	url     string
	data    ?string
	headers map[string]string
	params  map[string]string
}

fn append_query_params(url string, params map[string]string) string {
	if params.len == 0 {
		return url
	}

	mut keys := params.keys()
	keys.sort()

	mut parts := []string{cap: keys.len}
	for key in keys {
		parts << '${key}=${params[key]}'
	}

	sep := if url.contains('?') { '&' } else { '?' }
	return url + sep + parts.join('&')
}

// Fetch backend for browsers
pub struct FetchBackend {
	fetch_fn fn (url string, options FetchOptions) !FetchResponse @[required]
}

pub struct FetchOptions {
	method  string
	headers map[string]string
	body    ?string
}

pub struct FetchResponse {
	status  int
	headers map[string]string
	body    string
}

pub fn fetch_backend(fetch_fn fn (url string, options FetchOptions) !FetchResponse) Backend {
	return FetchBackend{
		fetch_fn: fetch_fn
	}
}

pub fn (b &FetchBackend) do(req RequestConfig) !Response {
	url := append_query_params(req.url, req.params)

	options := FetchOptions{
		method:  req.method
		headers: req.headers
		body:    req.data
	}

	resp := b.fetch_fn(url, options)!

	return Response{
		status_code: resp.status
		headers:     resp.headers
		body:        resp.body
	}
}

// Request backend for Node.js
pub struct RequestBackend {
	request_fn fn (options RequestOptions) !RequestResponse @[required]
}

pub struct RequestOptions {
	method  string
	url     string
	headers map[string]string
	body    ?string
}

pub struct RequestResponse {
	status_code int
	headers     map[string]string
	body        string
}

pub fn request_backend(request_fn fn (options RequestOptions) !RequestResponse) Backend {
	return RequestBackend{
		request_fn: request_fn
	}
}

pub fn (b &RequestBackend) do(req RequestConfig) !Response {
	url := append_query_params(req.url, req.params)

	options := RequestOptions{
		method:  req.method
		url:     url
		headers: req.headers
		body:    req.data
	}

	resp := b.request_fn(options)!

	return Response{
		status_code: resp.status_code
		headers:     resp.headers
		body:        resp.body
	}
}

// Default HTTP backend using V's net.http
pub struct HttpBackend {}

fn http_method_from_string(method string) !http.Method {
	return match method {
		'GET' { .get }
		'POST' { .post }
		'PUT' { .put }
		'PATCH' { .patch }
		'DELETE' { .delete }
		'HEAD' { .head }
		else { return error('Unsupported method: ${method}') }
	}
}

pub fn (b &HttpBackend) do(req RequestConfig) !Response {
	url := append_query_params(req.url, req.params)

	mut header := http.new_header()
	for key, value in req.headers {
		header.add_custom(key, value) or {}
	}

	method := http_method_from_string(req.method)!

	mut config := http.FetchConfig{
		url:    url
		method: method
		header: header
		data:   req.data or { '' }
	}

	http_resp := http.fetch(config)!

	mut resp_headers := map[string]string{}
	for key in http_resp.header.keys() {
		resp_headers[key] = http_resp.header.get_custom(key) or { '' }
	}

	return Response{
		status_code: http_resp.status_code
		headers:     resp_headers
		body:        http_resp.body
	}
}
