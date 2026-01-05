module tests

import restful
import x.json2 as json

// Debug integration test using real DummyJSON API

fn test_debug_single_product() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!

	data := product_entity.data()
	id_val := data['id'] or { json.Any(0) }
	title_val := data['title'] or { json.Any('') }
	println('Debug: Single product data - ID: ${id_val}, Title: ${title_val}')

	assert id_val.int() == 1
	println('✓ Debug single product test passed')
}

fn test_debug_multiple_endpoints() ! {
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

		id_val := data['id'] or { json.Any(0) }
		title_val := data['title'] or { json.Any('') }
		println('Debug: ${endpoint} - ID: ${id_val}, Has title: ${title_val.str() != ''}')
		assert id_val.int() == id.int()
	}

	println('✓ Debug multiple endpoints test passed')
}

fn test_debug_custom_endpoint() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut custom := api.custom('quotes/random', true)
	quote_entity := custom.get(map[string]string{}, map[string]string{})!

	data := quote_entity.data()
	id_val := data['id'] or { json.Any(0) }
	quote_val := data['quote'] or { json.Any('') }
	println('Debug: Random quote - ID: ${id_val}, Quote: ${quote_val}')

	assert id_val.int() > 0
	println('✓ Debug custom endpoint test passed')
}

fn test_debug_query_parameters() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')

	params := {
		'select': 'title,price,brand'
	}
	product_entity := product_member.get(params, map[string]string{})!

	data := product_entity.data()
	title_val := data['title'] or { json.Any('') }
	price_val := data['price'] or { json.Any(0) }
	brand_val := data['brand'] or { json.Any('') }
	println('Debug: Query params - Title: ${title_val}, Price: ${price_val}, Brand: ${brand_val}')

	assert title_val.str() != ''
	println('✓ Debug query parameters test passed')
}

fn test_debug_custom_headers() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-Debug-Header', 'debug-value')

	mut product_member := api.one('products', '1')
	headers := {
		'X-Custom-Debug': 'test'
	}
	product_entity := product_member.get(map[string]string{}, headers)!

	data := product_entity.data()
	id_val := data['id'] or { json.Any(0) }
	println('Debug: Custom headers - ID: ${id_val}')

	assert id_val.int() == 1
	println('✓ Debug custom headers test passed')
}

fn test_debug_url_generation() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})

	mut collection := api.all('products')
	mut member := api.one('products', '1')
	mut posts_collection := api.all('posts')
	mut post_comments := posts_collection.one('comments', '5')
	mut custom := api.custom('test', true)

	urls := [
		collection.url(),
		member.url(),
		post_comments.url(),
		custom.url(),
	]

	for url in urls {
		println('Debug: Generated URL - ${url}')
	}

	assert collection.url() == 'https://dummyjson.com/products'
	println('✓ Debug URL generation test passed')
}

fn test_debug_header_inheritance() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	api.header('X-Debug-API', 'debug-api-value')

	mut collection := api.all('products')
	api_headers := api.headers()
	collection_headers := collection.headers()

	println('Debug: API Headers - ${api_headers}')
	println('Debug: Collection Headers - ${collection_headers}')

	// API headers are stored in the API object
	assert api_headers['X-Debug-API'] == 'debug-api-value'

	// Collection starts with empty headers but inherits during requests
	assert collection_headers.len == 0

	println('✓ Debug header inheritance test passed')
}

fn test_debug_entity_methods() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})
	mut product_member := api.one('products', '1')
	product_entity := product_member.get(map[string]string{}, map[string]string{})!

	id := product_entity.id()
	url := product_entity.url()
	data := product_entity.data()
	id_val := data['id'] or { json.Any(0) }

	println('Debug: Entity methods - ID: ${id}, URL: ${url}, Data ID: ${id_val}')

	assert id == '1'
	assert url == 'https://dummyjson.com/products/1'
	println('✓ Debug entity methods test passed')
}

fn test_debug_error_scenarios() ! {
	mut api := restful.restful('https://dummyjson.com', &restful.HttpBackend{})

	// Test with invalid endpoint
	mut custom := api.custom('invalid/endpoint', true)
	result := custom.get(map[string]string{}, map[string]string{}) or {
		println('Debug: Invalid endpoint result - Error caught')
		return
	}

	// Log the result
	println('Debug: Invalid endpoint result - ${result}')

	println('✓ Debug error scenarios test completed')
}

fn test_debug_all_real_integration() ! {
	println('\n=== Starting Debug DummyJSON Integration Tests ===\n')

	test_debug_single_product()!
	test_debug_multiple_endpoints()!
	test_debug_custom_endpoint()!
	test_debug_query_parameters()!
	test_debug_custom_headers()!
	test_debug_url_generation()!
	test_debug_header_inheritance()!
	test_debug_entity_methods()!
	test_debug_error_scenarios()!

	println('\n=== All Debug DummyJSON Integration Tests Completed ===\n')
}
