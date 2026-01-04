module restful

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

pub struct Response {
pub:
	status_code int
	headers     map[string]string
	body        string
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
	options := FetchOptions{
		method:  req.method
		headers: req.headers
		body:    req.data
	}

	resp := b.fetch_fn(req.url, options)!

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
	options := RequestOptions{
		method:  req.method
		url:     req.url
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

pub fn (b &HttpBackend) do(req RequestConfig) !Response {
	mut headers := http.new_header()

	for key, value in req.headers {
		headers.add_custom(key, value) or {}
	}

	mut client := http.Client
	{}

	match req.method {
		'GET' {
			resp := client.get(req.url)!
			return Response{
				status_code: resp.status_code
				headers:     resp.headers
				body:        resp.body
			}
		}
		'POST' {
			resp := client.post(req.url, req.data or { '' })!
			return Response{
				status_code: resp.status_code
				headers:     resp.headers
				body:        resp.body
			}
		}
		'PUT' {
			resp := client.put(req.url, req.data or { '' })!
			return Response{
				status_code: resp.status_code
				headers:     resp.headers
				body:        resp.body
			}
		}
		'PATCH' {
			resp := client.patch(req.url, req.data or { '' })!
			return Response{
				status_code: resp.status_code
				headers:     resp.headers
				body:        resp.body
			}
		}
		'DELETE' {
			resp := client.delete(req.url)!
			return Response{
				status_code: resp.status_code
				headers:     resp.headers
				body:        resp.body
			}
		}
		'HEAD' {
			resp := client.head(req.url)!
			return Response{
				status_code: resp.status_code
				headers:     resp.headers
				body:        resp.body
			}
		}
		else {
			return error('Unsupported method: ${req.method}')
		}
	}
}
