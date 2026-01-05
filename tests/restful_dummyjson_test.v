module tests

import restful
import x.json2 as json

// Restful integration test using real DummyJSON API

fn test_restful_api_creation() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	// Test that API is created and can create collections
	mut collection := api.all('products')
	assert collection.url() == 'https://dummyjson.com/products'
	println('✓ Restful API creation test passed')
}

fn test_restful_collection_creation() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut collection := api.all('products')
	assert collection.url() == 'https://dummyjson.com/products'
	println('✓ Restful collection creation test passed')
}

fn test_restful_member_creation() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut member := api.one('products', '1')
	assert member.url() == 'https://dummyjson.com/products/1'
	println('✓ Restful member creation test passed')
}

fn test_restful_custom_creation() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut custom := api.custom('quotes/random', true)
	assert custom.url() == 'https://dummyjson.com/quotes/random'
	println('✓ Restful custom creation test passed')
}

fn test_restful_get_request() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!
	
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() == 1
	println('✓ Restful GET request test passed')
}

fn test_restful_with_params() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	
	params := {'select': 'title,price,brand'}
	product_entity := product_member.get(params, map[string]string{})!
	
	data := product_entity.data()
	assert data['title'] or { json.Any('') }.str() != ''
	assert data['price'] or { json.Any(0) }.int() > 0
	println('✓ Restful with params test passed')
}

fn test_restful_with_headers() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-Restful-Test', 'restful-value')
	
	mut product_member := api.one('products', '1')
	headers := {'X-Custom-Restful': 'test'}
	product_entity := product_member.get(map[string]string{}, headers)!
	
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() == 1
	println('✓ Restful with headers test passed')
}

fn test_restful_multiple_endpoints() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	endpoints := [
		['products', '1'],
		['users', '1'],
		['posts', '1'],
		['comments', '1'],
		['quotes', '1'],
		['todos', '1'],
	]
	
	for endpoint_id in endpoints {
		endpoint := endpoint_id[0]
		id := endpoint_id[1]
		mut member := api.one(endpoint, id)
		entity := member.get(map[string]string{}, map[string]string{})!
		data := entity.data()
		
		assert data['id'] or { json.Any(0) }.int() == id.int()
	}
	
	println('✓ Restful multiple endpoints test passed')
}

fn test_restful_custom_endpoints() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	custom_endpoints := [
		'quotes/random',
		'todos/random',
	]
	
	for endpoint in custom_endpoints {
		mut custom := api.custom(endpoint, true)
		entity := custom.get(map[string]string{}, map[string]string{})!
		data := entity.data()
		
		assert data['id'] or { json.Any(0) }.int() > 0
	}
	
	println('✓ Restful custom endpoints test passed')
}

fn test_restful_url_patterns() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	// Test various URL patterns
	assert api.all('products').url() == 'https://dummyjson.com/products'
	assert api.one('products', '1').url() == 'https://dummyjson.com/products/1'
	
	mut posts_collection := api.all('posts')
	mut post_comments := posts_collection.one('comments', '5')
	assert post_comments.url() == 'https://dummyjson.com/posts/5/comments'
	
	assert api.custom('special/endpoint', true).url() == 'https://dummyjson.com/special/endpoint'
	
	println('✓ Restful URL patterns test passed')
}

fn test_restful_header_management() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-API-Key', 'test-key')
	api.header('X-Request-ID', '12345')
	
	mut collection := api.all('products')
	api_headers := api.headers()
	collection_headers := collection.headers()
	
	assert api_headers['X-API-Key'] == 'test-key'
	assert api_headers['X-Request-ID'] == '12345'
	assert collection_headers.len == 0
	
	println('✓ Restful header management test passed')
}

fn test_restful_entity_operations() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!
	
	// Test entity methods
	id := product_entity.id()
	url := product_entity.url()
	data := product_entity.data()
	
	assert id == '1'
	assert url == 'https://dummyjson.com/products/1'
	assert data['id'] or { json.Any(0) }.int() == 1
	assert data['title'] or { json.Any('') }.str() != ''
	
	println('✓ Restful entity operations test passed')
}

fn test_restful_query_variations() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	
	// Test different query combinations
	queries := [
		{'select': 'title'},
		{'select': 'title,price'},
		{'select': 'title,price,brand'},
	]
	
	for query in queries {
		product_entity := product_member.get(query, map[string]string{})!
		data := product_entity.data()
		assert data['title'] or { json.Any('') }.str() != ''
	}
	
	println('✓ Restful query variations test passed')
}

fn test_restful_error_resilience() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	// Test with potentially problematic endpoints
	endpoints := [
		'invalid/endpoint',
		'products/999999', // non-existent product
	]
	
	for endpoint in endpoints {
		mut custom := api.custom(endpoint, true)
		result := custom.get(map[string]string{}, map[string]string{}) or {
			// Expected to fail, that's fine
			continue
		}
		// If we get here, log it
		_ := result
	}
	
	println('✓ Restful error resilience test passed')
}

fn test_all_restful_real_integration() ! {
	println('\n=== Starting Restful DummyJSON Integration Tests ===\n')
	
	test_restful_api_creation()!
	test_restful_collection_creation()!
	test_restful_member_creation()!
	test_restful_custom_creation()!
	test_restful_get_request()!
	test_restful_with_params()!
	test_restful_with_headers()!
	test_restful_multiple_endpoints()!
	test_restful_custom_endpoints()!
	test_restful_url_patterns()!
	test_restful_header_management()!
	test_restful_entity_operations()!
	test_restful_query_variations()!
	test_restful_error_resilience()!
	
	println('\n=== All Restful DummyJSON Integration Tests Completed ===\n')
}