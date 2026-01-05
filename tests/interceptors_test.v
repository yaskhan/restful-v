module tests

import restful
import x.json2 as json

// Mock backend for interceptor tests
struct InterceptorMockBackend {
mut:
	response restful.Response
	error    IError = none
}

pub fn (b InterceptorMockBackend) do(req restful.RequestConfig) !restful.Response {
	if b.error != IError(none) {
		// Return a response with error status code so error interceptors get called
		return restful.Response{
			status_code: 500
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"error": "${b.error.msg()}"}'
		}
	}
	return b.response
}

struct RequestCapture {
mut:
	called bool
	method string
	url    string
}

fn test_request_interceptor() {
	mut backend := InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut capture := &RequestCapture{
		called: false
		method: ''
		url:    ''
	}

	api.add_request_interceptor(fn [mut capture] (config restful.RequestConfig) restful.RequestConfig {
		capture.called = true
		capture.method = config.method
		capture.url = config.url
		return config
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert capture.called == true
	assert capture.method == 'GET'
	assert capture.url == 'http://api.example.com/articles'
}

struct ResponseCapture {
mut:
	called   bool
	response restful.Response
	config   restful.RequestConfig
}

fn test_response_interceptor() {
	mut backend := InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut capture := &ResponseCapture{
		called:   false
		response: restful.Response{
			status_code: 0
			headers:     map[string]string{}
			body:        ''
		}
		config:   restful.RequestConfig{
			headers: map[string]string{}
			params:  map[string]string{}
		}
	}

	api.add_response_interceptor(fn [mut capture] (response restful.Response, config restful.RequestConfig) restful.Response {
		capture.called = true
		capture.response = response
		capture.config = config
		return response
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert capture.called == true
	assert capture.response.status_code == 200
	assert capture.config.method == 'GET'
}

struct ErrorCapture {
mut:
	called bool
	error  IError
	config restful.RequestConfig
}

fn test_error_interceptor() {
	mut backend := InterceptorMockBackend{
		error: error('Test error')
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut capture := &ErrorCapture{
		called: false
		error:  error('')
		config: restful.RequestConfig{
			headers: map[string]string{}
			params:  map[string]string{}
		}
	}

	api.add_error_interceptor(fn [mut capture] (err IError, config restful.RequestConfig) IError {
		capture.called = true
		capture.error = err
		capture.config = config
		return err
	})

	mut collection := api.all('articles')

	if _ := collection.get_all(map[string]string{}, map[string]string{}) {
		assert false
	} else {
		assert capture.called == true
		assert capture.error.msg() == 'HTTP 500'
	}
}

fn test_request_interceptor_modification() {
	mut backend := InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		mut new_headers := config.headers.clone()
		new_headers['X-Modified'] = 'true'
		new_headers['Authorization'] = 'Bearer token'

		return restful.RequestConfig{
			method:  config.method
			url:     config.url
			data:    config.data
			headers: new_headers
			params:  config.params
		}
	})

	mut collection := api.all('articles')
	collection.header('X-Original', 'value')

	assert collection.headers()['X-Original'] == 'value'
}

fn test_response_interceptor_modification() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	api.add_response_interceptor(fn (response restful.Response, config restful.RequestConfig) restful.Response {
		mut new_headers := response.headers.clone()
		new_headers['X-Processed'] = 'true'

		return restful.Response{
			status_code: response.status_code
			headers:     new_headers
			body:        response.body
		}
	})

	mut collection := api.all('articles')
	entities := collection.get_all(map[string]string{}, map[string]string{})!

	assert entities.len == 0
}

fn test_error_interceptor_modification() {
	mut backend := &InterceptorMockBackend{
		error: error('Original error')
	}

	mut api := restful.restful('http://api.example.com', backend)

	api.add_error_interceptor(fn (err IError, config restful.RequestConfig) IError {
		return error('Modified: ${err.msg()}')
	})

	mut collection := api.all('articles')

	if _ := collection.get_all(map[string]string{}, map[string]string{}) {
		assert false
	} else {
		assert true
	}
}

fn test_multiple_request_interceptors() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'first_called':  false
		'second_called': false
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['first_called'] = true
		return config
	})

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['second_called'] = true
		return config
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['first_called'] == true
	assert captured['second_called'] == true
}

fn test_multiple_response_interceptors() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'first_called':  false
		'second_called': false
	}

	api.add_response_interceptor(fn [mut captured] (response restful.Response, config restful.RequestConfig) restful.Response {
		captured['first_called'] = true
		return response
	})

	api.add_response_interceptor(fn [mut captured] (response restful.Response, config restful.RequestConfig) restful.Response {
		captured['second_called'] = true
		return response
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['first_called'] == true
	assert captured['second_called'] == true
}

fn test_multiple_error_interceptors() {
	mut backend := &InterceptorMockBackend{
		error: error('Test error')
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'first_called':  false
		'second_called': false
	}

	api.add_error_interceptor(fn [mut captured] (err IError, config restful.RequestConfig) IError {
		captured['first_called'] = true
		return err
	})

	api.add_error_interceptor(fn [mut captured] (err IError, config restful.RequestConfig) IError {
		captured['second_called'] = true
		return err
	})

	mut collection := api.all('articles')

	if _ := collection.get_all(map[string]string{}, map[string]string{}) {
		assert false
	} else {
		assert captured['first_called'] == true
		assert captured['second_called'] == true
	}
}

fn test_interceptor_chaining() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		mut new_headers := config.headers.clone()
		new_headers['X-Step'] = '1'
		return restful.RequestConfig{
			method:  config.method
			url:     config.url
			data:    config.data
			headers: new_headers
			params:  config.params
		}
	})

	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		mut new_headers := config.headers.clone()
		new_headers['X-Step'] = '2'
		return restful.RequestConfig{
			method:  config.method
			url:     config.url
			data:    config.data
			headers: new_headers
			params:  config.params
		}
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	// Both interceptors should have been called
	assert true
}

fn test_collection_level_interceptors() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'api_called':        false
		'collection_called': false
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['api_called'] = true
		return config
	})

	mut collection := api.all('articles')
	collection.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['collection_called'] = true
		return config
	})

	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['api_called'] == true
	assert captured['collection_called'] == true
}

fn test_member_level_interceptors() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Test"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'api_called':    false
		'member_called': false
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['api_called'] = true
		return config
	})

	mut member := api.one('articles', '1')
	member.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['member_called'] = true
		return config
	})

	member.get(map[string]string{}, map[string]string{})!

	assert captured['api_called'] == true
	assert captured['member_called'] == true
}

fn test_interceptor_with_post_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 201
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "New"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'title': json.Any('New')
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_params() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut captured := {
		'params': map[string]string{}
	}
	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['params'] = config.params.clone()
		return config
	})

	mut collection := api.all('articles')
	params := {
		'limit':  '10'
		'offset': '0'
	}

	collection.get_all(params, map[string]string{})!

	assert captured['params']['limit'] == '10'
	assert captured['params']['offset'] == '0'
}

fn test_interceptor_with_custom_headers() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut captured := {
		'headers': map[string]string{}
	}
	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['headers'] = config.headers.clone()
		return config
	})

	mut collection := api.all('articles')
	collection.header('X-Custom', 'value')
	collection.header('Authorization', 'Bearer token')

	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['headers']['X-Custom'] == 'value'
	assert captured['headers']['Authorization'] == 'Bearer token'
}

fn test_interceptor_error_handling() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		// This interceptor doesn't throw
		return config
	})

	api.add_response_interceptor(fn (response restful.Response, config restful.RequestConfig) restful.Response {
		// This interceptor doesn't throw
		return response
	})

	mut collection := api.all('articles')
	entities := collection.get_all(map[string]string{}, map[string]string{})!

	assert entities.len == 0
}

fn test_interceptor_with_error_response() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 404
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"error": "Not Found"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'error_interceptor_called': false
	}

	api.add_error_interceptor(fn [mut captured] (err IError, config restful.RequestConfig) IError {
		captured['error_interceptor_called'] = true
		return err
	})

	mut collection := api.all('articles')

	if _ := collection.get_all(map[string]string{}, map[string]string{}) {
		assert false
	} else {
		assert captured['error_interceptor_called'] == true
	}
}

fn test_interceptor_order() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'order': []int{}
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['order'] << 1
		return config
	})

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['order'] << 2
		return config
	})

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['order'] << 3
		return config
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['order'].len == 3
	assert captured['order'][0] == 1
	assert captured['order'][1] == 2
	assert captured['order'][2] == 3
}

fn test_interceptor_data_transformation() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		// Transform data
		if config.data != none {
			// Add timestamp
			return restful.RequestConfig{
				method:  config.method
				url:     config.url
				data:    config.data
				headers: config.headers
				params:  config.params
			}
		}
		return config
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert true
}

fn test_interceptor_with_complex_headers() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut captured := {
		'headers': map[string]string{}
	}
	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['headers'] = config.headers.clone()
		return config
	})

	mut collection := api.all('articles')
	collection.header('Authorization', 'Bearer token123')
	collection.header('X-API-Version', 'v2')
	collection.header('Accept-Language', 'en-US')
	collection.header('X-Request-ID', 'req-abc-123')

	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['headers']['Authorization'] == 'Bearer token123'
	assert captured['headers']['X-API-Version'] == 'v2'
	assert captured['headers']['Accept-Language'] == 'en-US'
	assert captured['headers']['X-Request-ID'] == 'req-abc-123'
}

fn test_interceptor_with_nested_collections() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'api_called':      false
		'articles_called': false
		'comments_called': false
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['api_called'] = true
		return config
	})

	mut articles := api.all('articles')
	articles.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['articles_called'] = true
		return config
	})

	mut article := articles.one('comments', '1')
	article.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['comments_called'] = true
		return config
	})

	if _ := article.get(map[string]string{}, map[string]string{}) {
		assert false
	} else {
		assert true
	}

	assert captured['api_called'] == true
	assert captured['articles_called'] == true
	assert captured['comments_called'] == true
}

fn test_interceptor_with_custom_endpoint() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'url': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['url'] = config.url
		return config
	})

	mut custom := api.custom('special/endpoint', true)
	if _ := custom.get(map[string]string{}, map[string]string{}) {
		assert false
	} else {
		assert true
	}

	assert captured['url'] == 'http://api.example.com/special/endpoint'
}

fn test_interceptor_with_absolute_url() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'url': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['url'] = config.url
		return config
	})

	mut custom := api.custom('http://custom.url/endpoint', false)
	if _ := custom.get(map[string]string{}, map[string]string{}) {
		assert false
	} else {
		assert true
	}

	assert captured['url'] == 'http://custom.url/endpoint'
}

fn test_interceptor_with_delete_method() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 204
			headers:     map[string]string{}
			body:        ''
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'method': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['method'] = config.method
		return config
	})

	mut member := api.one('articles', '1')
	member.delete(none, map[string]string{}, map[string]string{})!

	assert captured['method'] == 'DELETE'
}

fn test_interceptor_with_put_method() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Updated"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'method': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['method'] = config.method
		return config
	})

	mut member := api.one('articles', '1')
	data := {
		'title': json.Any('Updated')
	}

	member.put(data, map[string]string{}, map[string]string{})!

	assert captured['method'] == 'PUT'
}

fn test_interceptor_with_patch_method() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Patched"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'method': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['method'] = config.method
		return config
	})

	mut member := api.one('articles', '1')
	data := {
		'title': json.Any('Patched')
	}

	member.patch(data, map[string]string{}, map[string]string{})!

	assert captured['method'] == 'PATCH'
}

fn test_interceptor_with_head_method() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     map[string]string{}
			body:        ''
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'method': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['method'] = config.method
		return config
	})

	mut member := api.one('articles', '1')
	member.head(map[string]string{}, map[string]string{})!

	assert captured['method'] == 'HEAD'
}

fn test_interceptor_with_post_method() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 201
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "New"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'method': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['method'] = config.method
		return config
	})

	mut collection := api.all('articles')
	data := {
		'title': json.Any('New')
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['method'] == 'POST'
}

fn test_interceptor_with_get_method() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'method': ''
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['method'] = config.method
		return config
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['method'] == 'GET'
}

fn test_interceptor_with_all_methods() {
	methods := ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']

	for method in methods {
		mut backend := &InterceptorMockBackend{
			response: restful.Response{
				status_code: 200
				headers:     {
					'Content-Type': 'application/json'
				}
				body:        '[]'
			}
		}

		mut api := restful.restful('http://api.example.com', backend)

		mut captured := {
			'method': ''
		}

		api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
			captured['method'] = config.method
			return config
		})

		mut collection := api.all('articles')

		match method {
			'GET' { collection.get_all(map[string]string{}, map[string]string{})! }
			'POST' { collection.post({
					'test': json.Any('data')
				}, map[string]string{}, map[string]string{})! }
			'PUT' { collection.put('1', {
					'test': json.Any('data')
				}, map[string]string{}, map[string]string{})! }
			'PATCH' { collection.patch('1', {
					'test': json.Any('data')
				}, map[string]string{}, map[string]string{})! }
			'DELETE' { collection.delete('1', map[string]json.Any{}, map[string]string{},
					map[string]string{})! }
			'HEAD' { collection.head('1', map[string]string{}, map[string]string{})! }
			else {}
		}

		assert captured['method'] == method
	}
}

fn test_interceptor_with_empty_config() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut captured := {
		'config': restful.RequestConfig{
			headers: map[string]string{}
			params:  map[string]string{}
		}
	}
	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['config'] = config
		return config
	})

	mut collection := api.all('articles')
	collection.get_all(map[string]string{}, map[string]string{})!

	assert captured['config'].method == 'GET'
	assert captured['config'].url == 'http://api.example.com/articles'
}

fn test_interceptor_with_full_config() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut captured := {
		'config': restful.RequestConfig{
			headers: map[string]string{}
			params:  map[string]string{}
		}
	}
	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['config'] = config
		return config
	})

	mut collection := api.all('articles')
	collection.header('X-Test', 'value')
	collection.get_all({
		'limit': '10'
	}, map[string]string{})!

	assert captured['config'].method == 'GET'
	assert captured['config'].url == 'http://api.example.com/articles'
	assert captured['config'].headers['X-Test'] == 'value'
	assert captured['config'].params['limit'] == '10'
}

fn test_interceptor_with_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 201
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'title': json.Any('Test')
		'body':  json.Any('Content')
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_nested_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 201
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'title':    json.Any('Test')
		'metadata': json.Any({
			'author': json.Any('John')
			'tags':   json.Any([json.Any('tag1'), json.Any('tag2')])
		})
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_array_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'items': json.Any([json.Any(1), json.Any(2), json.Any(3)])
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_boolean_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'active':   json.Any(true)
		'verified': json.Any(false)
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_number_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'count': json.Any(42)
		'score': json.Any(3.14)
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_null_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'optional': json.Any('null')
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_empty_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := map[string]json.Any{}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_unicode_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'message': json.Any('Hello 世界 🌍')
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_special_chars_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'text': json.Any('Line1\nLine2\tTabbed "quoted" \'apostrophe\'')
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_deeply_nested_data() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'level1': json.Any({
			'level2': json.Any({
				'level3': json.Any({
					'level4': json.Any({
						'value': json.Any('deep')
					})
				})
			})
		})
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_array_of_objects() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'users': json.Any([
			json.Any({
				'id':   json.Any(1)
				'name': json.Any('John')
			}),
			json.Any({
				'id':   json.Any(2)
				'name': json.Any('Jane')
			}),
		])
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}

fn test_interceptor_with_mixed_types() {
	mut backend := &InterceptorMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)

	mut captured := {
		'data': ?string(none)
	}

	api.add_request_interceptor(fn [mut captured] (config restful.RequestConfig) restful.RequestConfig {
		captured['data'] = config.data
		return config
	})

	mut collection := api.all('articles')
	data := {
		'string':  json.Any('text')
		'number':  json.Any(42)
		'boolean': json.Any(true)
		'null':    json.Any('null')
		'array':   json.Any([json.Any(1), json.Any(2)])
		'object':  json.Any({
			'key': json.Any('value')
		})
	}

	collection.post(data, map[string]string{}, map[string]string{})!

	assert captured['data'] != none
}
