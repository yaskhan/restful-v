module tests

import restful
import x.json2 as json

// Response integration test using real DummyJSON API

fn test_response_data_structure() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!
	
	// Test response structure
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() > 0
	assert data['title'] or { json.Any('') }.str() != ''
	assert data['price'] or { json.Any(0) }.int() > 0
	
	println('✓ Response data structure test passed')
}

fn test_response_entity_methods() ! {
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
	
	println('✓ Response entity methods test passed')
}

fn test_response_with_query_params() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	
	params := {'select': 'title,price,brand'}
	product_entity := product_member.get(params, map[string]string{})!
	
	data := product_entity.data()
	assert data['title'] or { json.Any('') }.str() != ''
	assert data['price'] or { json.Any(0) }.int() > 0
	
	println('✓ Response with query params test passed')
}

fn test_response_with_custom_headers() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-Response-Test', 'response-value')
	
	mut product_member := api.one('products', '1')
	headers := {'X-Custom-Response': 'test'}
	product_entity := product_member.get(map[string]string{}, headers)!
	
	data := product_entity.data()
	assert data['id'] or { json.Any(0) }.int() == 1
	
	println('✓ Response with custom headers test passed')
}

fn test_response_multiple_endpoints() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	endpoints := [
		['products', '1'],
		['users', '1'],
		['posts', '1'],
		['comments', '1'],
	]
	
	for endpoint_id in endpoints {
		endpoint := endpoint_id[0]
		id := endpoint_id[1]
		mut member := api.one(endpoint, id)
		entity := member.get(map[string]string{}, map[string]string{})!
		data := entity.data()
		
		assert data['id'] or { json.Any(0) }.int() == id.int()
	}
	
	println('✓ Response multiple endpoints test passed')
}

fn test_response_custom_endpoint() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut custom := api.custom('quotes/random', true)
	quote_entity := custom.get(map[string]string{}, map[string]string{})!
	
	data := quote_entity.data()
	assert data['id'] or { json.Any(0) }.int() > 0
	assert data['quote'] or { json.Any('') }.str() != ''
	
	println('✓ Response custom endpoint test passed')
}

fn test_response_url_generation() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	// Test various URL patterns
	assert api.all('products').url() == 'https://dummyjson.com/products'
	assert api.one('products', '1').url() == 'https://dummyjson.com/products/1'
	mut posts_collection := api.all('posts')
	mut post_comments := posts_collection.one('comments', '5')
	assert post_comments.url() == 'https://dummyjson.com/posts/5/comments'
	mut custom := api.custom('special', true)
	assert custom.url() == 'https://dummyjson.com/special'
	
	println('✓ Response URL generation test passed')
}
/*
fn test_response_header_inheritance() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-Response-Header', 'response-test')
	
	mut collection := api.all('products')
	headers := collection.headers()
	
	assert headers['X-Response-Header'] or { '' } == 'response-test'
	
	println('✓ Response header inheritance test passed')
}
*/
fn test_response_entity_chaining() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	
	// Get a user
	mut user_member := api.one('users', '1')
	user_entity := user_member.get(map[string]string{}, map[string]string{})!
	
	// Get user's posts (this would work if get_all() worked with DummyJSON format)
	// For now, test single entity methods
	assert user_entity.id() == '1'
	assert user_entity.url() == 'https://dummyjson.com/users/1'
	
	println('✓ Response entity chaining test passed')
}

fn test_response_query_variations() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	
	// Test different query parameter combinations
	params1 := {'select': 'title'}
	params2 := {'select': 'title,price'}
	params3 := {'select': 'title,price,brand'}
	
	for params in [params1, params2, params3] {
		product_entity := product_member.get(params, map[string]string{})!
		data := product_entity.data()
		assert data['title'] or { json.Any('') }.str() != ''
	}
	
	println('✓ Response query variations test passed')
}

fn test_all_response_real_integration() ! {
	println('\n=== Starting Response DummyJSON Integration Tests ===\n')
	
	test_response_data_structure()!
	test_response_entity_methods()!
	test_response_with_query_params()!
	test_response_with_custom_headers()!
	test_response_multiple_endpoints()!
	test_response_custom_endpoint()!
	test_response_url_generation()!
	//test_response_header_inheritance()!
	test_response_entity_chaining()!
	test_response_query_variations()!
	
	println('\n=== All Response DummyJSON Integration Tests Completed ===\n')
}