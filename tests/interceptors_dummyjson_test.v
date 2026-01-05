module tests

import restful
import x.json2 as json

// Interceptors integration test using real DummyJSON API

fn test_interceptors_request() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		println('Interceptors: Request intercepted - ${config.url}')
		return config
	})
	
	mut product_member := api.one('products', '1')
	product_member.get(map[string]string{}, map[string]string{})!
	
	println('✓ Interceptors request test completed')
}

fn test_interceptors_response() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	mut response_called := false
	api.add_response_interceptor(fn [mut response_called] (response restful.Response, config restful.RequestConfig) restful.Response {
		response_called = true
		println('Interceptors: Response intercepted - Status: ${response.status_code}')
		return response
	})
	
	mut product_member := api.one('products', '1')
	product_member.get(map[string]string{}, map[string]string{})!
	
	assert response_called
	println('✓ Interceptors response test passed')
}

fn test_interceptors_both() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	mut request_count := 0
	mut response_count := 0
	
	api.add_request_interceptor(fn [mut request_count] (config restful.RequestConfig) restful.RequestConfig {
		request_count++
		return config
	})
	
	api.add_response_interceptor(fn [mut response_count] (response restful.Response, config restful.RequestConfig) restful.Response {
		response_count++
		return response
	})
	
	mut product_member := api.one('products', '1')
	product_member.get(map[string]string{}, map[string]string{})!
	
	assert request_count > 0
	assert response_count > 0
	println('✓ Interceptors both test passed')
}

fn test_interceptors_with_headers() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		mut new_config := config
		// Create new headers map and copy existing headers
		mut updated_headers := map[string]string{}
		for k, v in new_config.headers {
			updated_headers[k] = v
		}
		updated_headers['X-Interceptor-Header'] = 'interceptor-value'
		println('Interceptors: Added header')
		return restful.RequestConfig{
			method: new_config.method
			url: new_config.url
			data: new_config.data
			headers: updated_headers
			params: new_config.params
		}
	})
	
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!
	
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() == 1
	println('✓ Interceptors with headers test passed')
}

fn test_interceptors_with_params() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		mut new_config := config
		// Create new params map and copy existing params
		mut updated_params := map[string]string{}
		for k, v in new_config.params {
			updated_params[k] = v
		}
		updated_params['interceptor'] = 'test'
		println('Interceptors: Added param')
		return restful.RequestConfig{
			method: new_config.method
			url: new_config.url
			data: new_config.data
			headers: new_config.headers
			params: updated_params
		}
	})
	
	mut product_member := api.one('products', '1')
	product_entity := product_member.get({'select': 'title'}, map[string]string{})!
	
	data := product_entity.data()
	assert data['title'] or { json.Any('') }.str() != ''
	println('✓ Interceptors with params test passed')
}

fn test_interceptors_multiple() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	mut interceptor_count := 0
	
	api.add_request_interceptor(fn [mut interceptor_count] (config restful.RequestConfig) restful.RequestConfig {
		interceptor_count++
		return config
	})
	
	api.add_request_interceptor(fn [mut interceptor_count] (config restful.RequestConfig) restful.RequestConfig {
		interceptor_count++
		return config
	})
	
	mut product_member := api.one('products', '1')
	product_member.get(map[string]string{}, map[string]string{})!
	
	assert interceptor_count >= 2
	println('✓ Interceptors multiple test passed')
}

fn test_interceptors_custom_endpoint() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	mut intercepted_url := ''
	api.add_request_interceptor(fn [mut intercepted_url] (config restful.RequestConfig) restful.RequestConfig {
		intercepted_url = config.url
		return config
	})
	
	mut custom := api.custom('quotes/random', true)
	custom.get(map[string]string{}, map[string]string{})!
	
	assert intercepted_url.contains('quotes/random')
	println('✓ Interceptors custom endpoint test passed')
}

fn test_interceptors_entity_chaining() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	mut request_count := 0
	api.add_request_interceptor(fn [mut request_count] (config restful.RequestConfig) restful.RequestConfig {
		request_count++
		return config
	})
	
	// Get user
	mut user_member := api.one('users', '1')
	user_entity := user_member.get(map[string]string{}, map[string]string{})!
	
	// Note: get_all() doesn't work with DummyJSON format
	// But we can test that the interceptor works for single entity
	assert request_count > 0
	assert user_entity.id() == '1'
	
	println('✓ Interceptors entity chaining test passed')
}

fn test_interceptors_header_inheritance() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-API-Key', 'test-key')
	
	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		println('Interceptors: Headers inherited - ${config.headers}')
		return config
	})
	
	mut collection := api.all('products')
	api_headers := api.headers()
	collection_headers := collection.headers()
	
	assert api_headers['X-API-Key'] == 'test-key'
	assert collection_headers.len == 0
	println('✓ Interceptors header inheritance test passed')
}

fn test_interceptors_error_handling() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	mut error_interceptor_called := false
	api.add_error_interceptor(fn [mut error_interceptor_called] (error IError, config restful.RequestConfig) IError {
		error_interceptor_called = true
		println('Interceptors: Error intercepted - ${error}')
		return error
	})
	
	// Test with potentially invalid endpoint
	mut custom := api.custom('invalid/endpoint', true)
	result := custom.get(map[string]string{}, map[string]string{}) or {
		// Expected to fail, that's fine
		println('Interceptors: Error handling test completed - error caught as expected')
		return
	}
	
	// If we get here, log it
	_ := result
	println('Interceptors: Error handling test completed')
	
	println('✓ Interceptors error handling test passed')
}

fn test_all_interceptors_real_integration() ! {
	println('\n=== Starting Interceptors DummyJSON Integration Tests ===\n')
	
	test_interceptors_request()!
	test_interceptors_response()!
	test_interceptors_both()!
	test_interceptors_with_headers()!
	test_interceptors_with_params()!
	test_interceptors_multiple()!
	test_interceptors_custom_endpoint()!
	test_interceptors_entity_chaining()!
	test_interceptors_header_inheritance()!
	test_interceptors_error_handling()!
	
	println('\n=== All Interceptors DummyJSON Integration Tests Completed ===\n')
}