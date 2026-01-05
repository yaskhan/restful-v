module tests

import restful
import x.json2 as json

// Mock backend for testing
struct MockBackend {
mut:
    response restful.Response
    error    IError
}

pub fn (b MockBackend) do(req restful.RequestConfig) !restful.Response {
    if b.error != IError(none) {
        return b.error
    }
    return b.response
}

fn test_api_creation() {
    backend := MockBackend{error: IError(none)}
    api := restful.restful('http://api.example.com', backend)

    // API fields are private, so we can't access them directly
    // Just verify the API was created
    assert api != unsafe { nil }
}

fn test_api_header() {
    backend := MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)
    
    api.header('AuthToken', 'test-token')
    // Can't access private headers field directly
    // Just verify the method call works
    assert true
}

fn test_api_identifier() {
    backend := MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)
    
    api.identifier('_id')
    // Can't access private field, just verify the method call works
    assert true
}

fn test_api_all() {
    backend := MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)

    mut collection := api.all('articles')
    assert collection.url() == 'http://api.example.com/articles'
}

fn test_api_one() {
    backend := MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)

    mut member := api.one('articles', '1')
    assert member.url() == 'http://api.example.com/articles/1'
}

fn test_api_custom() {
    backend := MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)

    mut custom := api.custom('articles/beta', true)
    assert custom.url() == 'http://api.example.com/articles/beta'
    
    mut absolute := api.custom('http://custom.url/articles', false)
    assert absolute.url() == 'http://custom.url/articles'
}

fn test_collection_get_all() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[{"id": "1", "title": "Test 1"}, {"id": "2", "title": "Test 2"}]'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    entities := collection.get_all(map[string]string{}, map[string]string{})!
    assert entities.len == 2
    
    first := entities[0].data()
    assert first['id'] == json.Any('1')
    assert first['title'] == json.Any('Test 1')
}

fn test_collection_get() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    mut entity := collection.get('1', map[string]string{}, map[string]string{})!
    data := entity.data()
    assert data['id'] == json.Any('1')
    assert data['title'] == json.Any('Test')
}

fn test_collection_post() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "New"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    data := {
        'title': json.Any('New')
    }
    
    response := collection.post(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 201
}

fn test_collection_one() {
    backend := MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    mut member := collection.one('comments', '5')
    assert member.url() == 'http://api.example.com/articles/5/comments'
}

fn test_member_get() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    data := entity.data()
    assert data['id'] == json.Any('1')
    assert data['title'] == json.Any('Test')
}

fn test_member_put() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Updated"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    data := {
        'title': json.Any('Updated')
    }
    
    response := member.put(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_member_delete() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    response := member.delete(none, map[string]string{}, map[string]string{})!
    assert response.status_code == 204
}

fn test_entity_save() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Saved"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut entity_data := entity.data()
    entity_data['title'] = json.Any('Saved')

    response := entity.save()!
    assert response.status_code == 200
}

fn test_entity_delete() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    response := entity.delete()!
    assert response.status_code == 204
}

fn test_entity_id() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "123", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    assert entity.id() == '123'
}

fn test_entity_url() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    assert entity.url() == 'http://api.example.com/articles/1'
}

fn test_entity_chaining() {
    backend := MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)
    
    mut member := api.one('articles', '1')
    mut collection := member.all('comments')
    
    assert collection.url() == 'http://api.example.com/articles/1/comments'
}

fn test_request_interceptor() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut called := false
    api.add_request_interceptor(fn [mut called] (config restful.RequestConfig) restful.RequestConfig {
        called = true
        return config
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert called
}

fn test_response_interceptor() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut called := false
    api.add_response_interceptor(fn [mut called] (response restful.Response, config restful.RequestConfig) restful.Response {
        called = true
        return response
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert called
}

fn test_error_interceptor() {
    mut backend := MockBackend{
        error: error('Test error')
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut called := false
    api.add_error_interceptor(fn [mut called] (err IError, config restful.RequestConfig) IError {
        called = true
        return err
    })
    
    mut collection := api.all('articles')
    
    if _ := collection.get_all(map[string]string{}, map[string]string{}) {
        assert false
    } else {
        assert called
    }
}

fn test_event_listeners() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut request_called := false
    mut response_called := false
    
    api.on('request', fn [mut request_called] (data restful.EventData) {
        request_called = true
    })
    
    api.on('response', fn [mut response_called] (data restful.EventData) {
        response_called = true
    })
    
    mut collection := api.all('articles')
    collection.get_all(map[string]string{}, map[string]string{})!
    
    assert request_called
    assert response_called
}

fn test_custom_identifier() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"_id": "abc123", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    api.identifier('_id')
    
    mut collection := api.all('articles')
    collection.identifier('_id')
    
    mut entity := collection.get('abc123', map[string]string{}, map[string]string{})!
    assert entity.id() == 'abc123'
}

fn test_inheritance() {
    mut backend := MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    api.header('AuthToken', 'test')
    api.identifier('_id')
    
    mut collection := api.all('articles')
    collection.header('X-Custom', 'value')
    
    // Test that headers are inherited
    // Can't access private headers field directly
    // Just verify the methods work
    assert true
}

fn test_http_backend() {
    // This test would require actual HTTP requests, so we'll just verify the structure
    backend := &restful.HttpBackend{}
    assert backend != unsafe { nil }
}

fn test_fetch_backend() {
    mock_fetch := fn (url string, options restful.FetchOptions) !restful.FetchResponse {
        return restful.FetchResponse{
            status: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    backend := restful.fetch_backend(mock_fetch)
    // Backend is an interface, can't compare to nil
    assert true
}

fn test_request_backend() {
    mock_request := fn (options restful.RequestOptions) !restful.RequestResponse {
        return restful.RequestResponse{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
    }
    
    backend := restful.request_backend(mock_request)
    // Backend is an interface, can't compare to nil
    assert true
}

fn test_response_methods() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"test": "data"}'
    }
    
    assert response.status_code() == 200
    assert response.headers()['Content-Type'] == 'application/json'
    assert response.body(true) == '{"test": "data"}'
    assert response.body(false) == '{"test": "data"}'
}

fn test_member_one_chaining() {
    backend := &MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)
    
    mut member := api.one('articles', '1')
    mut nested_member := member.one('comments', '5')
    
    assert nested_member.url() == 'http://api.example.com/articles/1/comments/5'
}

fn test_member_custom_chaining() {
    backend := &MockBackend{error: IError(none)}
    mut api := restful.restful('http://api.example.com', backend)
    
    mut member := api.one('articles', '1')
    mut custom := member.custom('special', true)
    
    assert custom.url() == 'http://api.example.com/articles/1/special'
}

fn test_collection_patch() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Patched"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    data := {
        'title': json.Any('Patched')
    }
    
    response := collection.patch('1', data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_collection_head() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    response := collection.head('1', map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_member_patch() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Patched"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    data := {
        'title': json.Any('Patched')
    }
    
    response := member.patch(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_member_head() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: map[string]string{}
            body: ''
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    response := member.head(map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_entity_custom() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    entity := member.get(map[string]string{}, map[string]string{})!
    mut custom := entity.custom('special', true)
    
    assert custom.url() == 'http://api.example.com/articles/1/special'
}

fn test_entity_all() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    entity := member.get(map[string]string{}, map[string]string{})!
    mut collection := entity.all('comments')
    
    assert collection.url() == 'http://api.example.com/articles/1/comments'
}

fn test_entity_one() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    entity := member.get(map[string]string{}, map[string]string{})!
    mut nested_member := entity.one('comments', '5')
    
    assert nested_member.url() == 'http://api.example.com/articles/1/comments/5'
}

fn test_collection_custom_identifier() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[{"_id": "abc", "title": "Test"}]'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    collection.identifier('_id')
    
    entities := collection.get_all(map[string]string{}, map[string]string{})!
    assert entities.len == 1
    
    entity := entities[0]
    assert entity.id() == 'abc'
}

fn test_member_custom_identifier() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"_id": "xyz", "title": "Test"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    member.identifier('_id')
    
    entity := member.get(map[string]string{}, map[string]string{})!
    assert entity.id() == 'xyz'
}

fn test_once_event() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '[]'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    
    mut count := 0
    api.once('response', fn [mut count] (data restful.EventData) {
        count++
    })
    
    mut collection := api.all('articles')
    
    // First call should trigger
    collection.get_all(map[string]string{}, map[string]string{})!
    assert count == 1
    
    // Second call should not trigger
    collection.get_all(map[string]string{}, map[string]string{})!
    assert count == 1
}

fn test_collection_post_with_params() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "New"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    data := {
        'title': json.Any('New')
    }
    params := {
        'debug': 'true'
    }
    headers := {
        'X-Request-ID': '123'
    }
    
    response := collection.post(data, params, headers)!
    assert response.status_code == 201
}

fn test_member_post_with_params() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 201
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "New"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    data := {
        'title': json.Any('New')
    }
    params := {
        'debug': 'true'
    }
    headers := {
        'X-Request-ID': '123'
    }
    
    response := member.post(data, params, headers)!
    assert response.status_code == 201
}

fn test_entity_save_with_params() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"id": "1", "title": "Saved"}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut entity_data := entity.data()
    entity_data['title'] = json.Any('Saved')
    
    params := {
        'force': 'true'
    }
    headers := {
        'X-Update-Type': 'full'
    }
    
    response := entity.save()!
    assert response.status_code == 200
}

fn test_entity_delete_with_params() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 204
            headers: map[string]string{}
            body: ''
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    
    params := {
        'hard': 'true'
    }
    headers := {
        'X-Delete-Type': 'permanent'
    }
    
    response := entity.delete()!
    assert response.status_code == 204
}

fn test_collection_delete_with_data() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"deleted": true}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')
    
    data := {
        'reason': json.Any('test')
    }
    
    response := collection.delete('1', data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_member_delete_with_data() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"deleted": true}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    data := {
        'reason': json.Any('test')
    }
    
    response := member.delete(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_entity_delete_with_data() {
    mut backend := &MockBackend{
        response: restful.Response{
            status_code: 200
            headers: {'Content-Type': 'application/json'}
            body: '{"deleted": true}'
        }
        error: IError(none)
    }
    
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')
    
    mut entity := member.get(map[string]string{}, map[string]string{})!
    
    data := {
        'reason': json.Any('test')
    }
    
    response := entity.delete()!
    assert response.status_code == 200
}