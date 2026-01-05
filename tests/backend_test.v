module tests

import restful

fn test_request_config_structure() {
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        data: none
        headers: {'Content-Type': 'application/json'}
        params: {'debug': 'true'}
    }
    
    assert config.method == 'GET'
    assert config.url == 'http://api.example.com/test'
    assert config.headers['Content-Type'] == 'application/json'
    assert config.params['debug'] == 'true'
}

fn test_response_structure() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"test": "data"}'
    }
    
    assert response.status_code == 200
    assert response.headers['Content-Type'] == 'application/json'
    assert response.body == '{"test": "data"}'
}

fn test_fetch_options_structure() {
    options := restful.FetchOptions{
        method: 'POST'
        headers: {'X-Custom': 'value'}
        body: '{"data": "test"}'
    }
    
    assert options.method == 'POST'
    assert options.headers['X-Custom'] == 'value'
    if options.body != none {
        body_str := options.body
        assert body_str! == '{"data": "test"}'
    }
}

fn test_fetch_response_structure() {
    response := restful.FetchResponse{
        status: 201
        headers: {'Content-Type': 'application/json'}
        body: '{"created": true}'
    }
    
    assert response.status == 201
    assert response.headers['Content-Type'] == 'application/json'
    assert response.body == '{"created": true}'
}

fn test_request_options_structure() {
    options := restful.RequestOptions{
        method: 'PUT'
        url: 'http://api.example.com/test'
        headers: {'X-Update': 'true'}
        body: '{"update": "data"}'
    }
    
    assert options.method == 'PUT'
    assert options.url == 'http://api.example.com/test'
    assert options.headers['X-Update'] == 'true'
    if options.body != none {
        body_str := options.body
        assert body_str! == '{"update": "data"}'
    }
}

fn test_request_response_structure() {
    response := restful.RequestResponse{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"updated": true}'
    }
    
    assert response.status_code == 200
    assert response.headers['Content-Type'] == 'application/json'
    assert response.body == '{"updated": true}'
}

fn test_fetch_backend_do() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        assert url == 'http://api.example.com/test'
        assert options.method == 'GET'
        return restful.FetchResponse{
            status: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"success": true}'
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.status_code == 200
    assert response.body == '{"success": true}'
}

fn test_request_backend_do() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        assert options.method == 'POST'
        assert options.url == 'http://api.example.com/test'
        return restful.RequestResponse{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"created": true}'
        }
    }
    
    backend := restful.request_backend(mock_request)
    
    config := restful.RequestConfig{
        method: 'POST'
        url: 'http://api.example.com/test'
        data: '{"data": "test"}'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.status_code == 201
    assert response.body == '{"created": true}'
}

fn test_http_backend_structure() {
    backend := &restful.HttpBackend{}
    assert backend != unsafe { nil }
}

fn test_fetch_backend_structure() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        return restful.FetchResponse{
            status: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    // Backend is an interface, just verify it works
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://test.com'
        headers: map[string]string{}
        params: map[string]string{}
    }
    _ := backend.do(config)!
}

fn test_request_backend_structure() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        return restful.RequestResponse{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.request_backend(mock_request)
    // Backend is an interface, just verify it works
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://test.com'
        headers: map[string]string{}
        params: map[string]string{}
    }
    _ := backend.do(config)!
}

fn test_backend_interface() {
    // Test that all backends implement the Backend interface
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        return restful.FetchResponse{
            status: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        return restful.RequestResponse{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    fetch_backend := restful.fetch_backend(mock_fetch)
    request_backend := restful.request_backend(mock_request)
    http_backend := &restful.HttpBackend{}
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://test.com'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    // All should be able to do requests
    _ := fetch_backend.do(config)!
    _ := request_backend.do(config)!
    // http_backend would need actual network, so we skip it
}

fn test_fetch_backend_with_data() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        assert options.body != none
        if options.body != none {
            assert options.body == '{"test": "data"}'
        }
        return restful.FetchResponse{
            status: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    
    config := restful.RequestConfig{
        method: 'POST'
        url: 'http://api.example.com/test'
        data: '{"test": "data"}'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    backend.do(config)!
}

fn test_request_backend_with_params() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        assert options.url == 'http://api.example.com/test?debug=true'
        return restful.RequestResponse{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.request_backend(mock_request)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: {'debug': 'true'}
    }
    
    backend.do(config)!
}

fn test_fetch_backend_error() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        return error('Network error')
    }
    
    backend := restful.fetch_backend(mock_fetch)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    if _ := backend.do(config) {
        assert false
    } else {
        assert true
    }
}

fn test_request_backend_error() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        return error('Request error')
    }
    
    backend := restful.request_backend(mock_request)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    if _ := backend.do(config) {
        assert false
    } else {
        assert true
    }
}

fn test_fetch_backend_all_methods() {
    methods := ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']
    
    for method in methods {
        mock_fetch := fn [method] (url string, options restful.FetchOptions) !restful.FetchResponse {
            assert options.method == method
            return restful.FetchResponse{
                status: 200
                headers: map[string]string{}
                body: ''
            }
        }
        
        backend := restful.fetch_backend(mock_fetch)
        
        config := restful.RequestConfig{
            method: method
            url: 'http://api.example.com/test'
            headers: map[string]string{}
            params: map[string]string{}
        }
        
        backend.do(config)!
    }
}

fn test_request_backend_all_methods() {
    methods := ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']
    
    for method in methods {
        mock_request := fn [method] (options restful.RequestOptions) !restful.RequestResponse {
            assert options.method == method
            return restful.RequestResponse{
                status_code: 200
                headers: map[string]string{}
                body: ''
            }
        }
        
        backend := restful.request_backend(mock_request)
        
        config := restful.RequestConfig{
            method: method
            url: 'http://api.example.com/test'
            headers: map[string]string{}
            params: map[string]string{}
        }
        
        backend.do(config)!
    }
}

fn test_fetch_backend_headers() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        assert options.headers['Authorization'] == 'Bearer token'
        assert options.headers['Content-Type'] == 'application/json'
        return restful.FetchResponse{
            status: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: {
            'Authorization': 'Bearer token'
            'Content-Type': 'application/json'
        }
        params: map[string]string{}
    }
    
    backend.do(config)!
}

fn test_request_backend_headers() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        assert options.headers['Authorization'] == 'Bearer token'
        assert options.headers['Content-Type'] == 'application/json'
        return restful.RequestResponse{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.request_backend(mock_request)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: {
            'Authorization': 'Bearer token'
            'Content-Type': 'application/json'
        }
        params: map[string]string{}
    }
    
    backend.do(config)!
}

fn test_fetch_backend_response_headers() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        return restful.FetchResponse{
            status: 200
            headers: {
                'Content-Type': 'application/json'
                'X-Custom': 'value'
            }
            body: '{"test": "data"}'
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.headers['Content-Type'] == 'application/json'
    assert response.headers['X-Custom'] == 'value'
}

fn test_request_backend_response_headers() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        return restful.RequestResponse{
            status_code: 200
            headers: {
                'Content-Type': 'application/json'
                'X-Custom': 'value'
            }
            body: '{"test": "data"}'
        }
    }
    
    backend := restful.request_backend(mock_request)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.headers['Content-Type'] == 'application/json'
    assert response.headers['X-Custom'] == 'value'
}

fn test_fetch_backend_empty_body() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        assert options.body == none
        return restful.FetchResponse{
            status: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.status_code == 204
}

fn test_request_backend_empty_body() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        assert options.body == none
        return restful.RequestResponse{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
    }
    
    backend := restful.request_backend(mock_request)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/test'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.status_code == 204
}

fn test_fetch_backend_complex_response() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        return restful.FetchResponse{
            status: 200
            headers: {
                'Content-Type': 'application/json'
                'Cache-Control': 'no-cache'
                'X-Request-ID': '12345'
            }
            body: '{"users": [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]}'
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    
    config := restful.RequestConfig{
        method: 'GET'
        url: 'http://api.example.com/users'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.status_code == 200
    assert response.headers['Content-Type'] == 'application/json'
    assert response.headers['X-Request-ID'] == '12345'
    assert response.body.contains('"users"')
}

fn test_request_backend_complex_response() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        return restful.RequestResponse{
            status_code: 201
            headers: {
                'Content-Type': 'application/json'
                'Location': '/users/1'
            }
            body: '{"id": 1, "name": "John", "created": true}'
        }
    }
    
    backend := restful.request_backend(mock_request)
    
    config := restful.RequestConfig{
        method: 'POST'
        url: 'http://api.example.com/users'
        data: '{"name": "John"}'
        headers: map[string]string{}
        params: map[string]string{}
    }
    
    response := backend.do(config)!
    assert response.status_code == 201
    assert response.headers['Location'] == '/users/1'
    assert response.body.contains('"created": true')
}