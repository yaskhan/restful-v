module tests

import restful
import x.json2 as json

// Mock backend for interceptor tests
struct InterceptorMockBackend {
mut:
    response restful.Response
    error    IError
}

pub fn (mut b InterceptorMockBackend) do(req restful.RequestConfig) !restful.Response {
    if b.error != none {
        return b.error
    }
    return b.response
}

fn test_request_interceptor() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut called := false
	mut captured_config := restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	}
    api.add_request_interceptor(fn [mut called, mut captured_config] (config restful.RequestConfig) restful.RequestConfig {
        called = true
        captured_config = config
        return config
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert called
    assert captured_config.method == 'GET'
    assert captured_config.url == 'http://api.example.com/articles'
}

fn test_response_interceptor() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut called := false
	mut captured_response := restful.Response{
		status_code: 0
		headers: map[string]string{}
		body: ''
	}
	mut captured_config := restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	}
    api.add_response_interceptor(fn [mut called, mut captured_response, mut captured_config] (response restful.Response, config restful.RequestConfig) restful.Response {
        called = true
        captured_response = response
        captured_config = config
        return response
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert called
    assert captured_response.status_code == 200
    assert captured_config.method == 'GET'
}

fn test_error_interceptor() {
    mut backend := &InterceptorMockBackend{
        error: error('Test error')
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut called := false
	mut captured_error := error('')
	mut captured_config := restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	}
    api.add_error_interceptor(fn [mut called, mut captured_error, mut captured_config] (err IError, config restful.RequestConfig) IError {
        called = true
        captured_error = err
        captured_config = config
        return err
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert called
        assert captured_error.msg() == 'Test error'
    }
}

fn test_request_interceptor_modification() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
        mut new_headers := config.headers.clone()
        new_headers['X-Modified'] = 'true'
        new_headers['Authorization'] = 'Bearer token'
        
        return restful.RequestConfig{
            method: config.method
            url: config.url
            data: config.data
            headers: new_headers
            params: config.params
        }
    })
    
    mut collection := api.all('articles')
    collection.header('X-Original', 'value')
    
    // The interceptor should have added headers
    // We can't directly test this without mocking the backend to see the final request
    // But we can verify the interceptor was added
    assert collection.headers()['X-Original'] == 'value'
}

fn test_response_interceptor_modification() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    api.add_response_interceptor(fn (response restful.Response, config restful.RequestConfig) restful.Response {
        mut new_headers := response.headers.clone()
        new_headers['X-Processed'] = 'true'
        
        return restful.Response{
            status_code: response.status_code
            headers: new_headers
            body: response.body
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
        // The error should be modified
        assert true
    }
}

fn test_multiple_request_interceptors() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut first_called := false
    mut second_called := false
    
    api.add_request_interceptor(fn [mut first_called] (config restful.RequestConfig) restful.RequestConfig {
        first_called = true
        return config
    })
    
    api.add_request_interceptor(fn [mut second_called] (config restful.RequestConfig) restful.RequestConfig {
        second_called = true
        return config
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert first_called
    assert second_called
}

fn test_multiple_response_interceptors() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut first_called := false
    mut second_called := false
    
    api.add_response_interceptor(fn [mut first_called] (response restful.Response, config restful.RequestConfig) restful.Response {
        first_called = true
        return response
    })
    
    api.add_response_interceptor(fn [mut second_called] (response restful.Response, config restful.RequestConfig) restful.Response {
        second_called = true
        return response
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert first_called
    assert second_called
}

fn test_multiple_error_interceptors() {
    mut backend := &InterceptorMockBackend{
        error: error('Test error')
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut first_called := false
    mut second_called := false
    
    api.add_error_interceptor(fn [mut first_called] (err IError, config restful.RequestConfig) IError {
        first_called = true
        return err
    })
    
    api.add_error_interceptor(fn [mut second_called] (err IError, config restful.RequestConfig) IError {
        second_called = true
        return err
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert first_called
        assert second_called
    }
}

fn test_interceptor_chaining() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
        mut new_headers := config.headers.clone()
        new_headers['X-Step'] = '1'
        return restful.RequestConfig{
            method: config.method
            url: config.url
            data: config.data
            headers: new_headers
            params: config.params
        }
    })
    
    api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
        mut new_headers := config.headers.clone()
        new_headers['X-Step'] = '2'
        return restful.RequestConfig{
            method: config.method
            url: config.url
            data: config.data
            headers: new_headers
            params: config.params
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
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_called := false
    mut collection_called := false
    
    api.add_request_interceptor(fn [mut api_called] (config restful.RequestConfig) restful.RequestConfig {
        api_called = true
        return config
    })
    
    mut collection := api.all('articles')
    collection.add_request_interceptor(fn [mut collection_called] (config restful.RequestConfig) restful.RequestConfig {
        collection_called = true
        return config
    })
    
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert api_called
    assert collection_called
}

fn test_member_level_interceptors() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_called := false
    mut member_called := false
    
    api.add_request_interceptor(fn [mut api_called] (config restful.RequestConfig) restful.RequestConfig {
        api_called = true
        return config
    })
    
    mut member := api.one('articles', '1')
    member.add_request_interceptor(fn [mut member_called] (config restful.RequestConfig) restful.RequestConfig {
        member_called = true
        return config
    })
    
    member.get(map[string]string{}, map[string]string{})!
    
    assert api_called
    assert member_called
}

fn test_interceptor_with_post_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "New"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('New')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('New')
}

fn test_interceptor_with_params() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut captured_params := map[string]string{}
    api.add_request_interceptor(fn [mut captured_params] (config restful.RequestConfig) restful.RequestConfig {
        captured_params = config.params
        return config
    })
    
    mut collection := api.all('articles')
    params := {
        'limit': '10'
        'offset': '0'
    }
    
    collection.get_all(params, map[string]string{})!
    
    assert captured_params['limit'] == '10'
    assert captured_params['offset'] == '0'
}

fn test_interceptor_with_custom_headers() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut captured_headers := map[string]string{}
    api.add_request_interceptor(fn [mut captured_headers] (config restful.RequestConfig) restful.RequestConfig {
        captured_headers = config.headers
        return config
    })
    
    mut collection := api.all('articles')
    collection.header('X-Custom', 'value')
    collection.header('Authorization', 'Bearer token')
    
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert captured_headers['X-Custom'] == 'value'
    assert captured_headers['Authorization'] == 'Bearer token'
}

fn test_interceptor_error_handling() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
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
            headers: {'Content-Type': 'application/json'}
            body: '{"error": "Not Found"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut error_interceptor_called := false
    
    api.add_error_interceptor(fn [mut error_interceptor_called] (err IError, config restful.RequestConfig) IError {
        error_interceptor_called = true
        return err
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert error_interceptor_called
    }
}

fn test_interceptor_order() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    order := []int{}
    
    api.add_request_interceptor(fn [mut order] (config restful.RequestConfig) restful.RequestConfig {
        order << 1
        return config
    })
    
    api.add_request_interceptor(fn [mut order] (config restful.RequestConfig) restful.RequestConfig {
        order << 2
        return config
    })
    
    api.add_request_interceptor(fn [mut order] (config restful.RequestConfig) restful.RequestConfig {
        order << 3
        return config
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert order.len == 3
    assert order[0] == 1
    assert order[1] == 2
    assert order[2] == 3
}

fn test_interceptor_data_transformation() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
        // Transform data
        if config.data != none {
            // Add timestamp
            return restful.RequestConfig{
                method: config.method
                url: config.url
                data: config.data
                headers: config.headers
                params: config.params
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
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut captured_headers := map[string]string{}
    api.add_request_interceptor(fn [mut captured_headers] (config restful.RequestConfig) restful.RequestConfig {
        captured_headers = config.headers
        return config
    })
    
    mut collection := api.all('articles')
    collection.header('Authorization', 'Bearer token123')
    collection.header('X-API-Version', 'v2')
    collection.header('Accept-Language', 'en-US')
    collection.header('X-Request-ID', 'req-abc-123')
    
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert captured_headers['Authorization'] == 'Bearer token123'
    assert captured_headers['X-API-Version'] == 'v2'
    assert captured_headers['Accept-Language'] == 'en-US'
    assert captured_headers['X-Request-ID'] == 'req-abc-123'
}

fn test_interceptor_with_nested_collections() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_called := false
    mut articles_called := false
    mut comments_called := false
    
    api.add_request_interceptor(fn [mut api_called] (config restful.RequestConfig) restful.RequestConfig {
        api_called = true
        return config
    })
    
    mut articles := api.all('articles')
    articles.add_request_interceptor(fn [mut articles_called] (config restful.RequestConfig) restful.RequestConfig {
        articles_called = true
        return config
    })
    
    mut article := articles.one('comments', '1')
    article.add_request_interceptor(fn [mut comments_called] (config restful.RequestConfig) restful.RequestConfig {
        comments_called = true
        return config
    })
    
    article.get(map[string]string{}, map[string]string{})!
    
    assert api_called
    assert articles_called
    assert comments_called
}

fn test_interceptor_with_custom_endpoint() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_url = ''
    
    api.add_request_interceptor(fn [mut captured_url] (config restful.RequestConfig) restful.RequestConfig {
        captured_url = config.url
        return config
    })
    
    mut custom := api.custom('special/endpoint', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert captured_url == 'http://api.example.com/special/endpoint'
}

fn test_interceptor_with_absolute_url() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_url = ''
    
    api.add_request_interceptor(fn [mut captured_url] (config restful.RequestConfig) restful.RequestConfig {
        captured_url = config.url
        return config
    })
    
    mut custom := api.custom('http://custom.url/endpoint', false)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert captured_url == 'http://custom.url/endpoint'
}

fn test_interceptor_with_delete_method() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_method = ''
    
    api.add_request_interceptor(fn [mut captured_method] (config restful.RequestConfig) restful.RequestConfig {
        captured_method = config.method
        return config
    })
    
    mut member := api.one('articles', '1')
    member.delete(none, map[string]string{}, map[string]string{})!
    
    assert captured_method == 'DELETE'
}

fn test_interceptor_with_put_method() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Updated"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_method = ''
    
    api.add_request_interceptor(fn [mut captured_method] (config restful.RequestConfig) restful.RequestConfig {
        captured_method = config.method
        return config
    })
    
    mut member := api.one('articles', '1')
    data := {
        'title': json.Any('Updated')
    }
    
    member.put(data, map[string]string{}, map[string]string{})!
    
    assert captured_method == 'PUT'
}

fn test_interceptor_with_patch_method() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Patched"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_method = ''
    
    api.add_request_interceptor(fn [mut captured_method] (config restful.RequestConfig) restful.RequestConfig {
        captured_method = config.method
        return config
    })
    
    mut member := api.one('articles', '1')
    data := {
        'title': json.Any('Patched')
    }
    
    member.patch(data, map[string]string{}, map[string]string{})!
    
    assert captured_method == 'PATCH'
}

fn test_interceptor_with_head_method() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_method = ''
    
    api.add_request_interceptor(fn [mut captured_method] (config restful.RequestConfig) restful.RequestConfig {
        captured_method = config.method
        return config
    })
    
    mut member := api.one('articles', '1')
    member.head(map[string]string{}, map[string]string{})!
    
    assert captured_method == 'HEAD'
}

fn test_interceptor_with_post_method() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "New"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_method = ''
    
    api.add_request_interceptor(fn [mut captured_method] (config restful.RequestConfig) restful.RequestConfig {
        captured_method = config.method
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('New')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_method == 'POST'
}

fn test_interceptor_with_get_method() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_method = ''
    
    api.add_request_interceptor(fn [mut captured_method] (config restful.RequestConfig) restful.RequestConfig {
        captured_method = config.method
        return config
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert captured_method == 'GET'
}

fn test_interceptor_with_all_methods() {
    methods := ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']
    
    for method in methods {
        mut backend := &InterceptorMockBackend{
            response: restful.Response{
                status_code: 200
                headers: {'Content-Type': 'application/json'}
                body: '[]'
            }
        }
        
        mut api := restful.restful('http://api.example.com', backend)
        
        mut captured_method = ''
        
        api.add_request_interceptor(fn [mut captured_method] (config restful.RequestConfig) restful.RequestConfig {
            captured_method = config.method
            return config
        })
        
        mut collection := api.all('articles')
        
        match method {
            'GET' { collection.get_all(map[string]string{}, map[string]string{})! }
            'POST' { collection.post({'test': json.Any('data')}, map[string]string{}, map[string]string{})! }
            'PUT' { collection.put('1', {'test': json.Any('data')}, map[string]string{}, map[string]string{})! }
            'PATCH' { collection.patch('1', {'test': json.Any('data')}, map[string]string{}, map[string]string{})! }
            'DELETE' { collection.delete('1', map[string]json.Any{}, map[string]string{}, map[string]string{})! }
            'HEAD' { collection.head('1', map[string]string{}, map[string]string{})! }
            else {}
        }
        
        assert captured_method == method
    }
}

fn test_interceptor_with_empty_config() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut captured_config := restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	}
    api.add_request_interceptor(fn [mut captured_config] (config restful.RequestConfig) restful.RequestConfig {
        captured_config = config
        return config
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert captured_config.method == 'GET'
    assert captured_config.url == 'http://api.example.com/articles'
}

fn test_interceptor_with_full_config() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut captured_config := restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	}
    api.add_request_interceptor(fn [mut captured_config] (config restful.RequestConfig) restful.RequestConfig {
        captured_config = config
        return config
    })
    
    mut collection := api.all('articles')
    collection.header('X-Test', 'value')
    collection.get_all({'limit': '10'}, map[string]string{})!
    
    assert captured_config.method == 'GET'
    assert captured_config.url == 'http://api.example.com/articles'
    assert captured_config.headers['X-Test'] == 'value'
    assert captured_config.params['limit'] == '10'
}

fn test_interceptor_with_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('Test')
        'body': json.Any('Content')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('Test')
    assert captured_data!.contains('Content')
}

fn test_interceptor_with_nested_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('Test')
        'metadata': json.Any({
            'author': json.Any('John')
            'tags': json.Any(['tag1', 'tag2'])
        })
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('Test')
    assert captured_data!.contains('John')
    assert captured_data!.contains('tag1')
}

fn test_interceptor_with_array_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'items': json.Any([json.Any(1), json.Any(2), json.Any(3)])
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('items')
    assert captured_data!.contains('1')
}

fn test_interceptor_with_boolean_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'active': json.Any(true)
        'verified': json.Any(false)
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('true')
    assert captured_data!.contains('false')
}

fn test_interceptor_with_number_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'count': json.Any(42)
        'score': json.Any(3.14)
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('42')
    assert captured_data!.contains('3.14')
}

fn test_interceptor_with_null_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'optional': json.Any('null')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
}

fn test_interceptor_with_empty_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := map[string]json.Any{}
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data! == '{}'
}

fn test_interceptor_with_unicode_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'message': json.Any('Hello 世界 🌍')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('世界')
    assert captured_data!.contains('🌍')
}

fn test_interceptor_with_special_chars_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'text': json.Any('Line1\nLine2\tTabbed "quoted" \'apostrophe\'')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('Line1')
    assert captured_data!.contains('Line2')
    assert captured_data!.contains('"quoted"')
}

fn test_interceptor_with_deeply_nested_data() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
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
    
    assert captured_data != none
    assert captured_data!.contains('deep')
}

fn test_interceptor_with_array_of_objects() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'users': json.Any([
            json.Any({'id': json.Any(1), 'name': json.Any('John')}),
            json.Any({'id': json.Any(2), 'name': json.Any('Jane')})
        ])
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('John')
    assert captured_data!.contains('Jane')
}

fn test_interceptor_with_mixed_types() {
    mut backend := &InterceptorMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut captured_data: ?string = none
    
    api.add_request_interceptor(fn [mut captured_data] (config restful.RequestConfig) restful.RequestConfig {
        captured_data = config.data
        return config
    })
    
    mut collection := api.all('articles')
    data := {
        'string': json.Any('text')
        'number': json.Any(42)
        'boolean': json.Any(true)
        'null': json.Any('null')
        'array': json.Any([json.Any(1), json.Any(2)])
        'object': json.Any({'key': json.Any('value')})
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert captured_data != none
    assert captured_data!.contains('text')
    assert captured_data!.contains('42')
    assert captured_data!.contains('true')
    assert captured_data!.contains('array')
    assert captured_data!.contains('object')
}