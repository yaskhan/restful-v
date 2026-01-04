module tests

import restful
import x.json2 as json

// Mock backend for event tests
struct EventMockBackend {
mut:
    response restful.Response
    error    IError
}

pub fn (mut b EventMockBackend) do(req restful.RequestConfig) !restful.Response {
    if b.error != none {
        return b.error
    }
    return b.response
}

fn test_api_on_request_event() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_called := false
	mut event_data := restful.EventData(restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	})
    api.on('request', fn [mut event_called, mut event_data] (data restful.EventData) {
        event_called = true
        event_data = data
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert event_called
    if event_data is restful.RequestConfig {
        assert event_data.method == 'GET'
        assert event_data.url == 'http://api.example.com/articles'
    } else {
        assert false
    }
}

fn test_api_on_response_event() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_called := false
	mut event_data := restful.EventData(restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	})
    api.on('response', fn [mut event_called, mut event_data] (data restful.EventData) {
        event_called = true
        event_data = data
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert event_called
    if event_data is restful.Response {
        assert event_data.status_code == 200
        assert event_data.body == '[]'
    } else {
        assert false
    }
}

fn test_api_on_error_event() {
    mut backend := &EventMockBackend{
        error: error('Test error')
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_called := false
	mut event_data := restful.EventData(restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	})
    api.on('error', fn [mut event_called, mut event_data] (data restful.EventData) {
        event_called = true
        event_data = data
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert event_called
        if event_data is IError {
            assert event_data.msg() == 'Test error'
        } else {
            assert false
        }
    }
}

fn test_api_once_event() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_count := 0
    
    api.once('response', fn [mut event_count] (data restful.EventData) {
        event_count++
    })
    
    mut collection := api.all('articles')
    
    // First call should trigger
    collection.get_all(map[string]string{}, map[string]string{})!
    assert event_count == 1
    
    // Second call should not trigger
    collection.get_all(map[string]string{}, map[string]string{})!
    assert event_count == 1
}

fn test_multiple_event_listeners() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut first_called := false
    mut second_called := false
    
    api.on('response', fn [mut first_called] (data restful.EventData) {
        first_called = true
    })
    
    api.on('response', fn [mut second_called] (data restful.EventData) {
        second_called = true
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert first_called
    assert second_called
}

fn test_event_propagation() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_request_count := 0
    mut api_response_count := 0
    mut collection_request_count := 0
    mut collection_response_count := 0
    
    api.on('request', fn [mut api_request_count] (data restful.EventData) {
        api_request_count++
    })
    
    api.on('response', fn [mut api_response_count] (data restful.EventData) {
        api_response_count++
    })
    
    mut collection := api.all('articles')
    collection.on('request', fn [mut collection_request_count] (data restful.EventData) {
        collection_request_count++
    })
    
    collection.on('response', fn [mut collection_response_count] (data restful.EventData) {
        collection_response_count++
    })
    
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert api_request_count == 1
    assert api_response_count == 1
    assert collection_request_count == 1
    assert collection_response_count == 1
}

fn test_event_data_types() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_data := restful.RequestConfig{
		headers: map[string]string{}
		params: map[string]string{}
	}
	mut response_data := restful.Response{
		status_code: 0
		headers: map[string]string{}
		body: ''
	}
    api.on('request', fn [mut request_data] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_data = data
        }
    })
    
    api.on('response', fn [mut response_data] (data restful.EventData) {
        if data is restful.Response {
            response_data = data
        }
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert request_data.method == 'GET'
    assert request_data.url == 'http://api.example.com/articles'
    assert response_data.status_code == 200
    assert response_data.body == '[]'
}

fn test_event_with_error_data() {
    mut backend := &EventMockBackend{
        error: error('Network error')
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut error_data := error('')
    api.on('error', fn [mut error_data] (data restful.EventData) {
        if data is IError {
            error_data = data
        }
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert error_data.msg() == 'Network error'
    }
}

fn test_event_on_member() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_called := false
    
    mut member := api.one('articles', '1')
    member.on('request', fn [mut event_called] (data restful.EventData) {
        event_called = true
    })
    
    member.get(map[string]string{}, map[string]string{})!
    
    assert event_called
}

fn test_event_on_collection() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_called := false
    
    mut collection := api.all('articles')
    collection.on('response', fn [mut event_called] (data restful.EventData) {
        event_called = true
    })
    
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert event_called
}

fn test_event_once_on_member() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_count := 0
    
    mut member := api.one('articles', '1')
    member.once('response', fn [mut event_count] (data restful.EventData) {
        event_count++
    })
    
    // First call
    member.get(map[string]string{}, map[string]string{})!
    assert event_count == 1
    
    // Second call should not trigger
    member.get(map[string]string{}, map[string]string{})!
    assert event_count == 1
}

fn test_event_once_on_collection() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_count := 0
    
    mut collection := api.all('articles')
    collection.once('response', fn [mut event_count] (data restful.EventData) {
        event_count++
    })
    
    // First call
    collection.get_all(map[string]string{}, map[string]string{})!
    assert event_count == 1
    
    // Second call should not trigger
    collection.get_all(map[string]string{}, map[string]string{})!
    assert event_count == 1
}

fn test_event_with_custom_endpoint() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_called := false
    mut event_url = ''
    
    api.on('request', fn [mut event_called, mut event_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            event_called = true
            event_url = data.url
        }
    })
    
    mut custom := api.custom('special/endpoint', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert event_called
    assert event_url == 'http://api.example.com/special/endpoint'
}

fn test_event_with_absolute_url() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut event_url = ''
    
    api.on('request', fn [mut event_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            event_url = data.url
        }
    })
    
    mut custom := api.custom('http://custom.url/endpoint', false)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert event_url == 'http://custom.url/endpoint'
}

fn test_event_with_nested_collections() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_request_count := 0
    mut articles_request_count := 0
    mut comments_request_count := 0
    
    api.on('request', fn [mut api_request_count] (data restful.EventData) {
        api_request_count++
    })
    
    mut articles := api.all('articles')
    articles.on('request', fn [mut articles_request_count] (data restful.EventData) {
        articles_request_count++
    })
    
    mut comments := articles.one('comments', '5')
    comments.on('request', fn [mut comments_request_count] (data restful.EventData) {
        comments_request_count++
    })
    
    comments.get(map[string]string{}, map[string]string{})!
    
    assert api_request_count == 1
    assert articles_request_count == 1
    assert comments_request_count == 1
}

fn test_event_with_all_methods() {
    methods := ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']
    
    for method in methods {
        mut backend := &EventMockBackend{
            response: restful.Response{
                status_code: 200
                headers: {'Content-Type': 'application/json'}
                body: '[]'
            }
        }
        
        mut api := restful.restful('http://api.example.com', backend)
        
        mut event_method = ''
        
        api.on('request', fn [mut event_method] (data restful.EventData) {
            if data is restful.RequestConfig {
                event_method = data.method
            }
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
        
        assert event_method == method
    }
}

fn test_event_with_error_response() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 404
            headers: {'Content-Type': 'application/json'}
            body: '{"error": "Not Found"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut response_data := restful.Response{
		status_code: 0
		headers: map[string]string{}
		body: ''
	}
    api.on('response', fn [mut response_data] (data restful.EventData) {
        if data is restful.Response {
            response_data = data
        }
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        // Response event should still fire for non-2xx status codes
        // But the collection.get_all will return error
        // So we need to check if response event was called
        // Actually, looking at the implementation, response event fires before error check
        // So it should have been called
        assert response_data.status_code == 404
    }
}

fn test_event_with_server_error() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 500
            headers: {'Content-Type': 'application/json'}
            body: '{"error": "Internal Server Error"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut response_data := restful.Response{
		status_code: 0
		headers: map[string]string{}
		body: ''
	}
    api.on('response', fn [mut response_data] (data restful.EventData) {
        if data is restful.Response {
            response_data = data
        }
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert response_data.status_code == 500
    }
}

fn test_event_with_request_headers() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_headers := map[string]string{}
    api.on('request', fn [mut request_headers] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_headers = data.headers
        }
    })
    
    mut collection := api.all('articles')
    collection.header('X-Custom', 'value')
    collection.header('Authorization', 'Bearer token')
    
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert request_headers['X-Custom'] == 'value'
    assert request_headers['Authorization'] == 'Bearer token'
}

fn test_event_with_request_params() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_params := map[string]string{}
    api.on('request', fn [mut request_params] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_params = data.params
        }
    })
    
    mut collection := api.all('articles')
    params := {
        'limit': '10'
        'offset': '0'
    }
    
    collection.get_all(params, map[string]string{})!
    
    assert request_params['limit'] == '10'
    assert request_params['offset'] == '0'
}

fn test_event_with_request_data() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_data: ?string = none
    
    api.on('request', fn [mut request_data] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_data = data.data
        }
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('Test')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert request_data != none
    assert request_data!.contains('Test')
}

fn test_event_with_response_headers() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {
                'Content-Type': 'application/json'
                'X-Request-ID': '12345'
                'X-Response-Time': '23ms'
            }
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut response_headers := map[string]string{}
    api.on('response', fn [mut response_headers] (data restful.EventData) {
        if data is restful.Response {
            response_headers = data.headers
        }
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert response_headers['Content-Type'] == 'application/json'
    assert response_headers['X-Request-ID'] == '12345'
    assert response_headers['X-Response-Time'] == '23ms'
}

fn test_event_with_response_body() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[{"id": "1", "title": "Test"}]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut response_body = ''
    
    api.on('response', fn [mut response_body] (data restful.EventData) {
        if data is restful.Response {
            response_body = data.body
        }
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert response_body == '[{"id": "1", "title": "Test"}]'
}

fn test_event_with_response_status() {
    status_codes := [200, 201, 204, 400, 401, 403, 404, 500, 502, 503]
    
    for status_code in status_codes {
        mut backend := &EventMockBackend{
            response: restful.Response{
                status_code: status_code
                headers: {'Content-Type': 'application/json'}
                body: ''
            }
        }
        
        mut api := restful.restful('http://api.example.com', backend)
        
        mut event_status = 0
        
        api.on('response', fn [mut event_status] (data restful.EventData) {
            if data is restful.Response {
                event_status = data.status_code
            }
        })
        
        mut collection := api.all('articles')
        
        if status_code >= 200 && status_code < 400 {
            collection.get_all(map[string]string{}, map[string]string{})!
        } else {
            if _ := collection.get_all(map[string]string{}, map[string]string{}) {
                assert false
            }
        }
        
        assert event_status == status_code
    }
}

fn test_event_with_member_get() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    mut response_body = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    api.on('response', fn [mut response_body] (data restful.EventData) {
        if data is restful.Response {
            response_body = data.body
        }
    })
    
    mut member := api.one('articles', '1')
    member.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1'
    assert response_body == '{"id": "1", "title": "Test"}'
}

fn test_event_with_member_post() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "New"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut request_data: ?string = none
    mut response_status = 0
    
    api.on('request', fn [mut request_method, mut request_data] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
            request_data = data.data
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    data := {
        'title': json.Any('New')
    }
    
    member.post(data, map[string]string{}, map[string]string{})!
    
    assert request_method == 'POST'
    assert request_data != none
    assert request_data!.contains('New')
    assert response_status == 201
}

fn test_event_with_member_put() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Updated"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    data := {
        'title': json.Any('Updated')
    }
    
    member.put(data, map[string]string{}, map[string]string{})!
    
    assert request_method == 'PUT'
    assert response_status == 200
}

fn test_event_with_member_patch() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Patched"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    data := {
        'title': json.Any('Patched')
    }
    
    member.patch(data, map[string]string{}, map[string]string{})!
    
    assert request_method == 'PATCH'
    assert response_status == 200
}

fn test_event_with_member_delete() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    member.delete(none, map[string]string{}, map[string]string{})!
    
    assert request_method == 'DELETE'
    assert response_status == 204
}

fn test_event_with_member_head() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    member.head(map[string]string{}, map[string]string{})!
    
    assert request_method == 'HEAD'
    assert response_status == 200
}

fn test_event_with_collection_post() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "New"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('New')
    }
    
    collection.post(data, map[string]string{}, map[string]string{})!
    
    assert request_method == 'POST'
    assert response_status == 201
}

fn test_event_with_collection_put() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Updated"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('Updated')
    }
    
    collection.put('1', data, map[string]string{}, map[string]string{})!
    
    assert request_method == 'PUT'
    assert response_status == 200
}

fn test_event_with_collection_patch() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Patched"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut collection := api.all('articles')
    data := {
        'title': json.Any('Patched')
    }
    
    collection.patch('1', data, map[string]string{}, map[string]string{})!
    
    assert request_method == 'PATCH'
    assert response_status == 200
}

fn test_event_with_collection_delete() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut collection := api.all('articles')
    collection.delete('1', map[string]json.Any{}, map[string]string{}, map[string]string{})!
    
    assert request_method == 'DELETE'
    assert response_status == 204
}

fn test_event_with_collection_head() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut collection := api.all('articles')
    collection.head('1', map[string]string{}, map[string]string{})!
    
    assert request_method == 'HEAD'
    assert response_status == 200
}

fn test_event_with_collection_get() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_body = ''
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_body] (data restful.EventData) {
        if data is restful.Response {
            response_body = data.body
        }
    })
    
    mut collection := api.all('articles')
    entity := collection.get('1', map[string]string{}, map[string]string{})!
    
    assert request_method == 'GET'
    assert response_body == '{"id": "1", "title": "Test"}'
}

fn test_event_with_entity_save() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Saved"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    entity.save()!
    
    assert request_method == 'PUT'
    assert response_status == 200
}

fn test_event_with_entity_delete() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    entity.delete()!
    
    assert request_method == 'DELETE'
    assert response_status == 204
}

fn test_event_with_entity_chaining() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut comments := entity.all('comments')
    comments.get_all(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/comments'
}

fn test_event_with_collection_chaining() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut articles := api.all('articles')
    mut article := articles.one('comments', '5')
    mut authors := article.all('authors')
    authors.get_all(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/5/comments/authors'
}

fn test_event_with_custom_identifier() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"_id": "abc123", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    api.identifier('_id')
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut collection := api.all('articles')
    collection.identifier('_id')
    
    entity := collection.get('abc123', map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/abc123'
}

fn test_event_with_header_inheritance() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    api.header('AuthToken', 'test-token')
	mut request_headers := map[string]string{}
    api.on('request', fn [mut request_headers] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_headers = data.headers
        }
    })
    
    mut articles := api.all('articles')
    articles.header('X-Custom', 'value')
    
    articles.get_all(map[string]string{}, map[string]string{})!
    
    assert request_headers['AuthToken'] == 'test-token'
    assert request_headers['X-Custom'] == 'value'
}

fn test_event_with_interceptors() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_interceptor_called = false
    mut response_interceptor_called = false
    mut request_event_called = false
    mut response_event_called = false
    
    api.add_request_interceptor(fn [mut request_interceptor_called] (config restful.RequestConfig) restful.RequestConfig {
        request_interceptor_called = true
        return config
    })
    
    api.add_response_interceptor(fn [mut response_interceptor_called] (response restful.Response, config restful.RequestConfig) restful.Response {
        response_interceptor_called = true
        return response
    })
    
    api.on('request', fn [mut request_event_called] (data restful.EventData) {
        request_event_called = true
    })
    
    api.on('response', fn [mut response_event_called] (data restful.EventData) {
        response_event_called = true
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert request_interceptor_called
    assert response_interceptor_called
    assert request_event_called
    assert response_event_called
}

fn test_event_with_error_interceptor() {
    mut backend := &EventMockBackend{
        error: error('Test error')
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut error_interceptor_called = false
    mut error_event_called = false
    
    api.add_error_interceptor(fn [mut error_interceptor_called] (err IError, config restful.RequestConfig) IError {
        error_interceptor_called = true
        return err
    })
    
    api.on('error', fn [mut error_event_called] (data restful.EventData) {
        error_event_called = true
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert error_interceptor_called
        assert error_event_called
    }
}

fn test_event_with_multiple_listeners_same_event() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut listener1_called = false
    mut listener2_called = false
    mut listener3_called = false
    
    api.on('response', fn [mut listener1_called] (data restful.EventData) {
        listener1_called = true
    })
    
    api.on('response', fn [mut listener2_called] (data restful.EventData) {
        listener2_called = true
    })
    
    api.on('response', fn [mut listener3_called] (data restful.EventData) {
        listener3_called = true
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert listener1_called
    assert listener2_called
    assert listener3_called
}

fn test_event_with_mixed_once_and_on() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut on_count = 0
    mut once_count = 0
    
    api.on('response', fn [mut on_count] (data restful.EventData) {
        on_count++
    })
    
    api.once('response', fn [mut once_count] (data restful.EventData) {
        once_count++
    })
    
    mut collection := api.all('articles')
    
    // First call
    collection.get_all(map[string]string{}, map[string]string{})!
    assert on_count == 1
    assert once_count == 1
    
    // Second call
    collection.get_all(map[string]string{}, map[string]string{})!
    assert on_count == 2
    assert once_count == 1 // Should not increase
}

fn test_event_with_nested_member_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_count = 0
    mut articles_count = 0
    mut comments_count = 0
    mut authors_count = 0
    
    api.on('request', fn [mut api_count] (data restful.EventData) {
        api_count++
    })
    
    mut articles := api.all('articles')
    articles.on('request', fn [mut articles_count] (data restful.EventData) {
        articles_count++
    })
    
    mut comments := articles.one('comments', '5')
    comments.on('request', fn [mut comments_count] (data restful.EventData) {
        comments_count++
    })
    
    mut authors := comments.all('authors')
    authors.on('request', fn [mut authors_count] (data restful.EventData) {
        authors_count++
    })
    
    authors.get_all(map[string]string{}, map[string]string{})!
    
    assert api_count == 1
    assert articles_count == 1
    assert comments_count == 1
    assert authors_count == 1
}

fn test_event_with_custom_endpoint_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut custom := api.custom('special/endpoint', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/special/endpoint'
    assert response_status == 200
}

fn test_event_with_absolute_custom_endpoint_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut custom := api.custom('http://custom.url/endpoint', false)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://custom.url/endpoint'
}

fn test_event_with_entity_custom_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom := entity.custom('special', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/special'
}

fn test_event_with_entity_all_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut collection := entity.all('comments')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/comments'
}

fn test_event_with_entity_one_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut nested := entity.one('comments', '5')
    nested.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/comments/5'
}

fn test_event_with_collection_one_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut collection := api.all('articles')
    mut member := collection.one('comments', '5')
    member.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/5/comments'
}

fn test_event_with_collection_custom_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut collection := api.all('articles')
    mut custom := collection.custom('special', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/special'
}

fn test_event_with_member_one_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    mut nested := member.one('comments', '5')
    nested.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/comments/5'
}

fn test_event_with_member_all_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    mut collection := member.all('comments')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/comments'
}

fn test_event_with_member_custom_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    mut custom := member.custom('special', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/special'
}

fn test_event_with_entity_save_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Saved"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut request_url = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method, mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
            request_url = data.url
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    entity.save()!
    
    assert request_method == 'PUT'
    assert request_url == 'http://api.example.com/articles/1'
    assert response_status == 200
}

fn test_event_with_entity_delete_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_method = ''
    mut request_url = ''
    mut response_status = 0
    
    api.on('request', fn [mut request_method, mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_method = data.method
            request_url = data.url
        }
    })
    
    api.on('response', fn [mut response_status] (data restful.EventData) {
        if data is restful.Response {
            response_status = data.status_code
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    entity.delete()!
    
    assert request_method == 'DELETE'
    assert request_url == 'http://api.example.com/articles/1'
    assert response_status == 204
}

fn test_event_with_entity_id_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"_id": "abc123", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    api.identifier('_id')
    
    mut entity_id = ''
    
    api.on('response', fn [mut entity_id] (data restful.EventData) {
        if data is restful.Response {
            // Can't get entity ID from response directly
            // This test is more about verifying events fire
        }
    })
    
    mut collection := api.all('articles')
    collection.identifier('_id')
    
    entity := collection.get('abc123', map[string]string{}, map[string]string{})!
    
    assert entity.id() == 'abc123'
}

fn test_event_with_entity_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    
    assert entity.url() == 'http://api.example.com/articles/1'
    assert request_url == 'http://api.example.com/articles/1'
}

fn test_event_with_entity_data_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test", "count": 42}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut response_body = ''
    
    api.on('response', fn [mut response_body] (data restful.EventData) {
        if data is restful.Response {
            response_body = data.body
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    data := entity.data()
    
    assert data['id'] == json.Any('1')
    assert data['title'] == json.Any('Test')
    assert data['count'] == json.Any(42)
    assert response_body == '{"id": "1", "title": "Test", "count": 42}'
}

fn test_event_with_entity_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut comments := entity.all('comments')
    mut authors := comments.one('authors', '2')
    authors.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1/comments/2/authors'
}

fn test_event_with_collection_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut articles := api.all('articles')
    mut article := articles.one('comments', '5')
    mut authors := article.all('authors')
    authors.get_all(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/articles/5/comments/authors'
}

fn test_event_with_member_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    mut nested := member.one('comments', '5')
    mut authors := nested.all('authors')
    authors.get_all(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/articles/1/comments/5/authors'
}

fn test_event_with_custom_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut custom1 := api.custom('special', true)
    mut custom2 := custom1.custom('nested', true)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/special/nested'
}

fn test_event_with_entity_custom_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('nested', true)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1/special/nested'
}

fn test_event_with_entity_all_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut comments := entity.all('comments')
    mut authors := comments.all('authors')
    authors.get_all(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1/comments/authors'
}

fn test_event_with_entity_one_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut comments := entity.one('comments', '5')
    mut authors := comments.one('authors', '2')
    authors.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1/comments/5/authors'
}

fn test_event_with_collection_one_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut articles := api.all('articles')
    mut article := articles.one('comments', '5')
    mut authors := article.one('authors', '2')
    authors.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/articles/5/comments/2/authors'
}

fn test_event_with_collection_custom_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut articles := api.all('articles')
    mut custom1 := articles.custom('special', true)
    mut custom2 := custom1.custom('nested', true)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/articles/special/nested'
}

fn test_event_with_member_one_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    mut nested := member.one('comments', '5')
    mut authors := nested.one('authors', '2')
    authors.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/articles/1/comments/5/authors'
}

fn test_event_with_member_all_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    mut comments := member.all('comments')
    mut authors := comments.all('authors')
    authors.get_all(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/articles/1/comments/authors'
}

fn test_event_with_member_custom_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    mut custom1 := member.custom('special', true)
    mut custom2 := custom1.custom('nested', true)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 1
    assert request_urls[0] == 'http://api.example.com/articles/1/special/nested'
}

fn test_event_with_entity_save_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Saved"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    entity.save()!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1'
}

fn test_event_with_entity_delete_chaining_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    entity.delete()!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1'
}

fn test_event_with_entity_data_modification_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Modified"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_data: ?string = none
    
    api.on('request', fn [mut request_data] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_data = data.data
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut entity_data := entity.data()
    entity_data['title'] = json.Any('Modified')
    entity.save()!
    
    assert request_data != none
    assert request_data!.contains('Modified')
}

fn test_event_with_entity_identifier_inheritance_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"_id": "abc123", "title": "Test"}'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    api.identifier('_id')
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut articles := api.all('articles')
    articles.identifier('_id')
    
    entity := articles.get('abc123', map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/abc123'
    assert entity.id() == 'abc123'
}

fn test_event_with_entity_header_inheritance_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    api.header('AuthToken', 'test-token')
	mut request_headers := map[string]string{}
    api.on('request', fn [mut request_headers] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_headers = data.headers
        }
    })
    
    mut articles := api.all('articles')
    articles.header('X-Custom', 'value')
    
    mut article := articles.one('comments', '5')
    article.header('X-Nested', 'nested-value')
    
    article.get(map[string]string{}, map[string]string{})!
    
    assert request_headers['AuthToken'] == 'test-token'
    assert request_headers['X-Custom'] == 'value'
    assert request_headers['X-Nested'] == 'nested-value'
}

fn test_event_with_entity_interceptor_inheritance_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_interceptor_called = false
    mut articles_interceptor_called = false
    mut article_interceptor_called = false
    
    api.add_request_interceptor(fn [mut api_interceptor_called] (config restful.RequestConfig) restful.RequestConfig {
        api_interceptor_called = true
        return config
    })
    
    mut articles := api.all('articles')
    articles.add_request_interceptor(fn [mut articles_interceptor_called] (config restful.RequestConfig) restful.RequestConfig {
        articles_interceptor_called = true
        return config
    })
    
    mut article := articles.one('comments', '5')
    article.add_request_interceptor(fn [mut article_interceptor_called] (config restful.RequestConfig) restful.RequestConfig {
        article_interceptor_called = true
        return config
    })
    
    article.get(map[string]string{}, map[string]string{})!
    
    assert api_interceptor_called
    assert articles_interceptor_called
    assert article_interceptor_called
}

fn test_event_with_entity_event_propagation_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut api_request_count = 0
    mut api_response_count = 0
    mut articles_request_count = 0
    mut articles_response_count = 0
    mut article_request_count = 0
    mut article_response_count = 0
    
    api.on('request', fn [mut api_request_count] (data restful.EventData) {
        api_request_count++
    })
    
    api.on('response', fn [mut api_response_count] (data restful.EventData) {
        api_response_count++
    })
    
    mut articles := api.all('articles')
    articles.on('request', fn [mut articles_request_count] (data restful.EventData) {
        articles_request_count++
    })
    
    articles.on('response', fn [mut articles_response_count] (data restful.EventData) {
        articles_response_count++
    })
    
    mut article := articles.one('comments', '5')
    article.on('request', fn [mut article_request_count] (data restful.EventData) {
        article_request_count++
    })
    
    article.on('response', fn [mut article_response_count] (data restful.EventData) {
        article_response_count++
    })
    
    article.get(map[string]string{}, map[string]string{})!
    
    assert api_request_count == 1
    assert api_response_count == 1
    assert articles_request_count == 1
    assert articles_response_count == 1
    assert article_request_count == 1
    assert article_response_count == 1
}

fn test_event_with_entity_custom_endpoint_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom := entity.custom('special/endpoint', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/special/endpoint'
}

fn test_event_with_entity_absolute_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom := entity.custom('http://custom.url/endpoint', false)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://custom.url/endpoint'
}

fn test_event_with_entity_all_absolute_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut collection := entity.all('comments')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/comments'
}

fn test_event_with_entity_one_absolute_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut nested := entity.one('comments', '5')
    nested.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/comments/5'
}

fn test_event_with_entity_custom_absolute_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom := entity.custom('http://custom.url/endpoint', false)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://custom.url/endpoint'
}

fn test_event_with_entity_custom_relative_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom := entity.custom('special', true)
    custom.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/special'
}

fn test_event_with_entity_custom_nested_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('nested', true)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://api.example.com/articles/1/special/nested'
}

fn test_event_with_entity_custom_absolute_nested_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_url = ''
    
    api.on('request', fn [mut request_url] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_url = data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('http://custom.url/nested', false)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_url == 'http://custom.url/nested'
}

fn test_event_with_entity_custom_mixed_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('http://custom.url/nested', false)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://custom.url/nested'
}

fn test_event_with_entity_custom_relative_nested_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('nested', true)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1/special/nested'
}

fn test_event_with_entity_custom_absolute_relative_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('http://custom.url/special', false)
    mut custom2 := custom1.custom('nested', true)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://custom.url/special/nested'
}

fn test_event_with_entity_custom_absolute_absolute_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('http://custom.url/special', false)
    mut custom2 := custom1.custom('http://custom2.url/nested', false)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://custom2.url/nested'
}

fn test_event_with_entity_custom_relative_absolute_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('http://custom2.url/nested', false)
    custom2.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://custom2.url/nested'
}

fn test_event_with_entity_custom_multiple_relative_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('nested', true)
    mut custom3 := custom2.custom('deep', true)
    custom3.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://api.example.com/articles/1/special/nested/deep'
}

fn test_event_with_entity_custom_multiple_absolute_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('http://custom1.url/special', false)
    mut custom2 := custom1.custom('http://custom2.url/nested', false)
    mut custom3 := custom2.custom('http://custom3.url/deep', false)
    custom3.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://custom3.url/deep'
}

fn test_event_with_entity_custom_mixed_multiple_url_events() {
    mut backend := &EventMockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    mut api := restful.restful('http://api.example.com', backend)
	mut request_urls := []string{}
    api.on('request', fn [mut request_urls] (data restful.EventData) {
        if data is restful.RequestConfig {
            request_urls << data.url
        }
    })
    
    mut member := api.one('articles', '1')
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom1 := entity.custom('special', true)
    mut custom2 := custom1.custom('http://custom2.url/nested', false)
    mut custom3 := custom2.custom('deep', true)
    custom3.get(map[string]string{}, map[string]string{})!
    
    assert request_urls.len == 2
    assert request_urls[0] == 'http://api.example.com/articles/1'
    assert request_urls[1] == 'http://custom2.url/nested/deep'
}