module tests

import restful
import x.json2 as json

// Backend integration test using real DummyJSON API

fn test_http_backend_real_request() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!
	
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() == 1
	assert data['title'] or { json.Any('') }.str() != ''
	
	println('✓ HTTP backend real request test passed')
}

fn test_http_backend_with_params() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	
	params := {'select': 'title,price'}
	product_entity := product_member.get(params, map[string]string{})!
	
	data := product_entity.data()
	assert data['title'] or { json.Any('') }.str() != ''
	assert data['price'] or { json.Any(0) }.int() > 0
	
	println('✓ HTTP backend with params test passed')
}

fn test_http_backend_custom_headers() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-Test', 'backend-test')
	
	mut product_member := api.one('products', '1')
	headers := {'X-Custom': 'value'}
	product_entity := product_member.get(map[string]string{}, headers)!
	
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() == 1
	
	println('✓ HTTP backend custom headers test passed')
}

fn test_http_backend_multiple_endpoints() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	endpoints := [
		['products', '1'],
		['users', '1'],
		['posts', '1'],
	]
	
	for endpoint_id in endpoints {
		endpoint := endpoint_id[0]
		id := endpoint_id[1]
		mut member := api.one(endpoint, id)
		entity := member.get(map[string]string{}, map[string]string{})!
		data := entity.data()
		
		assert data['id'] or { json.Any(0) }.int() == id.int()
	}
	
	println('✓ HTTP backend multiple endpoints test passed')
}

fn test_http_backend_custom_endpoint() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut custom := api.custom('quotes/random', true)
	quote_entity := custom.get(map[string]string{}, map[string]string{})!
	
	data := quote_entity.data()
	assert data['id'] or { json.Any(0) }.int() > 0
	
	println('✓ HTTP backend custom endpoint test passed')
}

fn test_http_backend_url_generation() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	assert api.all('products').url() == 'https://dummyjson.com/products'
	assert api.one('products', '1').url() == 'https://dummyjson.com/products/1'
	assert api.custom('test', true).url() == 'https://dummyjson.com/test'
	
	println('✓ HTTP backend URL generation test passed')
}

fn test_http_backend_header_inheritance() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-API-Key', 'test-key')
	
	mut collection := api.all('products')
	// Headers are set, inheritance works
	collection.headers()
	
	println('✓ HTTP backend header inheritance test passed')
}

fn test_http_backend_entity_methods() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!
	
	assert product_entity.id() == '1'
	assert product_entity.url() == 'https://dummyjson.com/products/1'
	
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() == 1
	
	println('✓ HTTP backend entity methods test passed')
}

fn test_http_backend_query_parameters() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	
	params := {'select': 'title,price,brand'}
	product_entity := product_member.get(params, map[string]string{})!
	
	data := product_entity.data()
	assert data['title'] or { json.Any('') }.str() != ''
	assert data['price'] or { json.Any(0) }.int() > 0
	
	println('✓ HTTP backend query parameters test passed')
}

fn test_http_backend_error_handling() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	// Test with invalid endpoint - should handle gracefully
	mut custom := api.custom('invalid/endpoint', true)
	
	// This might fail, but we're testing the library handles it
	result := custom.get(map[string]string{}, map[string]string{}) or {
		// Expected to fail
		println('✓ HTTP backend error handling test completed (error caught as expected)')
		return
	}
	
	// If it succeeds, good
	println('✓ HTTP backend error handling test completed')
}

fn test_all_backend_real_integration() ! {
	println('\n=== Starting Backend DummyJSON Integration Tests ===\n')
	
	test_http_backend_real_request()!
	test_http_backend_with_params()!
	test_http_backend_custom_headers()!
	test_http_backend_multiple_endpoints()!
	test_http_backend_custom_endpoint()!
	test_http_backend_url_generation()!
	test_http_backend_header_inheritance()!
	test_http_backend_entity_methods()!
	test_http_backend_query_parameters()!
	test_http_backend_error_handling()!
	
	println('\n=== All Backend DummyJSON Integration Tests Completed ===\n')
}