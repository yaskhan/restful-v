module tests

import restful

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

fn test_response_status_code() {
    response := restful.Response{
        status_code: 201
        headers: map[string]string{}
        body: ''
    }
    
    assert response.status_code() == 201
}

fn test_response_headers() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Content-Type': 'application/json'
            'X-Custom': 'value'
            'Cache-Control': 'no-cache'
        }
        body: ''
    }
    
    headers := response.headers()
    assert headers['Content-Type'] == 'application/json'
    assert headers['X-Custom'] == 'value'
    assert headers['Cache-Control'] == 'no-cache'
}

fn test_response_body() {
    response := restful.Response{
        status_code: 200
        headers: map[string]string{}
        body: '{"users": [{"id": 1, "name": "John"}]}'
    }
    
    // Test with hydration (default)
    body_with_hydration := response.body(true)
    assert body_with_hydration == '{"users": [{"id": 1, "name": "John"}]}'
    
    // Test without hydration
    body_without_hydration := response.body(false)
    assert body_without_hydration == '{"users": [{"id": 1, "name": "John"}]}'
}

fn test_response_empty_body() {
    response := restful.Response{
        status_code: 204
        headers: map[string]string{}
        body: ''
    }
    
    assert response.body(true) == ''
    assert response.body(false) == ''
}

fn test_response_json_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"id": 1, "name": "Test", "active": true}'
    }
    
    body := response.body(true)
    assert body == '{"id": 1, "name": "Test", "active": true}'
}

fn test_response_array_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '[{"id": 1}, {"id": 2}, {"id": 3}]'
    }
    
    body := response.body(true)
    assert body == '[{"id": 1}, {"id": 2}, {"id": 3}]'
}

fn test_response_nested_json() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"user": {"id": 1, "profile": {"name": "John", "age": 30}}}'
    }
    
    body := response.body(true)
    assert body == '{"user": {"id": 1, "profile": {"name": "John", "age": 30}}}'
}

fn test_response_different_status_codes() {
    status_codes := [200, 201, 204, 400, 401, 403, 404, 500, 502, 503]
    
    for code in status_codes {
        response := restful.Response{
            status_code: code
            headers: map[string]string{}
            body: ''
        }
        
        assert response.status_code() == code
    }
}

fn test_response_with_empty_headers() {
    response := restful.Response{
        status_code: 200
        headers: map[string]string{}
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers.len == 0
}

fn test_response_with_multiple_headers() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Content-Type': 'application/json'
            'Content-Length': '123'
            'X-Request-ID': 'abc123'
            'X-Response-Time': '45ms'
            'Cache-Control': 'max-age=3600'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers.len == 5
    assert headers['Content-Type'] == 'application/json'
    assert headers['Content-Length'] == '123'
    assert headers['X-Request-ID'] == 'abc123'
    assert headers['X-Response-Time'] == '45ms'
    assert headers['Cache-Control'] == 'max-age=3600'
}

fn test_response_with_special_characters_in_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"message": "Hello, 世界! 🌍", "special": "äöü ñ ç"}'
    }
    
    body := response.body(true)
    assert body == '{"message": "Hello, 世界! 🌍", "special": "äöü ñ ç"}'
}

fn test_response_with_newlines_in_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'text/plain'}
        body: 'Line 1\nLine 2\nLine 3'
    }
    
    body := response.body(true)
    assert body == 'Line 1\nLine 2\nLine 3'
}

fn test_response_with_html_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'text/html'}
        body: '<html><body><h1>Hello</h1></body></html>'
    }
    
    body := response.body(true)
    assert body == '<html><body><h1>Hello</h1></body></html>'
}

fn test_response_with_xml_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/xml'}
        body: '<?xml version="1.0"?><root><item>Test</item></root>'
    }
    
    body := response.body(true)
    assert body == '<?xml version="1.0"?><root><item>Test</item></root>'
}

fn test_response_with_binary_like_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/octet-stream'}
        body: 'binary data here'
    }
    
    body := response.body(true)
    assert body == 'binary data here'
}

fn test_response_status_204_no_content() {
    response := restful.Response{
        status_code: 204
        headers: {'Content-Length': '0'}
        body: ''
    }
    
    assert response.status_code() == 204
    assert response.body(true) == ''
    assert response.body(false) == ''
}

fn test_response_status_304_not_modified() {
    response := restful.Response{
        status_code: 304
        headers: {'Cache-Control': 'max-age=3600'}
        body: ''
    }
    
    assert response.status_code() == 304
    assert response.body(true) == ''
}

fn test_response_with_error_status() {
    response := restful.Response{
        status_code: 404
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Not Found", "message": "Resource does not exist"}'
    }
    
    assert response.status_code() == 404
    assert response.body(true) == '{"error": "Not Found", "message": "Resource does not exist"}'
}

fn test_response_with_server_error() {
    response := restful.Response{
        status_code: 500
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Internal Server Error", "trace_id": "abc123"}'
    }
    
    assert response.status_code() == 500
    assert response.body(true) == '{"error": "Internal Server Error", "trace_id": "abc123"}'
}

fn test_response_header_case_sensitivity() {
    response := restful.Response{
        status_code: 200
        headers: {
            'content-type': 'application/json'
            'X-Custom-Header': 'value'
        }
        body: ''
    }
    
    headers := response.headers()
    // Headers should preserve case
    assert headers['content-type'] == 'application/json'
    assert headers['X-Custom-Header'] == 'value'
}

fn test_response_empty_headers_map() {
    response := restful.Response{
        status_code: 200
        headers: map[string]string{}
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers.len == 0
}

fn test_response_large_body() {
    large_body := '{"data": "' + 'x'.repeat(1000) + '"}'
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: large_body
    }
    
    assert response.body(true) == large_body
    assert response.body(false) == large_body
}

fn test_response_with_charset() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json; charset=utf-8'}
        body: '{"text": "Hello"}'
    }
    
    assert response.headers()['Content-Type'] == 'application/json; charset=utf-8'
}

fn test_response_with_auth_header() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Content-Type': 'application/json'
            'Authorization': 'Bearer token123'
            'WWW-Authenticate': 'Bearer realm="api"'
        }
        body: '{"authenticated": true}'
    }
    
    headers := response.headers()
    assert headers['Authorization'] == 'Bearer token123'
    assert headers['WWW-Authenticate'] == 'Bearer realm="api"'
}

fn test_response_with_cors_headers() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Access-Control-Allow-Origin': '*'
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE'
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers['Access-Control-Allow-Origin'] == '*'
    assert headers['Access-Control-Allow-Methods'] == 'GET, POST, PUT, DELETE'
}

fn test_response_with_pagination_headers() {
    response := restful.Response{
        status_code: 200
        headers: {
            'X-Total-Count': '100'
            'X-Page': '1'
            'X-Per-Page': '10'
            'Link': '<https://api.example.com/items?page=2>; rel="next"'
        }
        body: '[]'
    }
    
    headers := response.headers()
    assert headers['X-Total-Count'] == '100'
    assert headers['X-Page'] == '1'
    assert headers['X-Per-Page'] == '10'
    assert headers['Link'] == '<https://api.example.com/items?page=2>; rel="next"'
}

fn test_response_with_rate_limit_headers() {
    response := restful.Response{
        status_code: 200
        headers: {
            'X-RateLimit-Limit': '100'
            'X-RateLimit-Remaining': '99'
            'X-RateLimit-Reset': '1640000000'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers['X-RateLimit-Limit'] == '100'
    assert headers['X-RateLimit-Remaining'] == '99'
    assert headers['X-RateLimit-Reset'] == '1640000000'
}

fn test_response_with_etag() {
    response := restful.Response{
        status_code: 200
        headers: {
            'ETag': '"33a64df551425fcc55e4d42a148795d9f25f89d4"'
            'Last-Modified': 'Wed, 21 Oct 2015 07:28:00 GMT'
        }
        body: '{"data": "cached"}'
    }
    
    headers := response.headers()
    assert headers['ETag'] == '"33a64df551425fcc55e4d42a148795d9f25f89d4"'
    assert headers['Last-Modified'] == 'Wed, 21 Oct 2015 07:28:00 GMT'
}

fn test_response_with_set_cookie() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Set-Cookie': 'session=abc123; HttpOnly; Secure; SameSite=Strict'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers['Set-Cookie'] == 'session=abc123; HttpOnly; Secure; SameSite=Strict'
}

fn test_response_with_location_header() {
    response := restful.Response{
        status_code: 201
        headers: {
            'Location': '/api/users/123'
        }
        body: '{"id": 123}'
    }
    
    headers := response.headers()
    assert headers['Location'] == '/api/users/123'
}

fn test_response_with_retry_after() {
    response := restful.Response{
        status_code: 429
        headers: {
            'Retry-After': '60'
        }
        body: '{"error": "Too Many Requests"}'
    }
    
    headers := response.headers()
    assert headers['Retry-After'] == '60'
}

fn test_response_with_content_encoding() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Content-Encoding': 'gzip'
            'Content-Type': 'application/json'
        }
        body: 'compressed data'
    }
    
    headers := response.headers()
    assert headers['Content-Encoding'] == 'gzip'
}

fn test_response_with_transfer_encoding() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Transfer-Encoding': 'chunked'
        }
        body: 'chunked data'
    }
    
    headers := response.headers()
    assert headers['Transfer-Encoding'] == 'chunked'
}

fn test_response_with_vary_header() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Vary': 'Origin, Accept-Encoding'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers['Vary'] == 'Origin, Accept-Encoding'
}

fn test_response_with_pragma() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Pragma': 'no-cache'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers['Pragma'] == 'no-cache'
}

fn test_response_with_expires() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Expires': 'Thu, 31 Dec 2023 23:59:59 GMT'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers['Expires'] == 'Thu, 31 Dec 2023 23:59:59 GMT'
}

fn test_response_with_content_disposition() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Content-Disposition': 'attachment; filename="data.json"'
        }
        body: '{"data": "value"}'
    }
    
    headers := response.headers()
    assert headers['Content-Disposition'] == 'attachment; filename="data.json"'
}

fn test_response_with_all_common_headers() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Content-Type': 'application/json; charset=utf-8'
            'Content-Length': '45'
            'Cache-Control': 'max-age=3600'
            'ETag': '"abc123"'
            'Last-Modified': 'Wed, 21 Oct 2015 07:28:00 GMT'
            'X-Request-ID': 'req-123'
            'X-Response-Time': '23ms'
            'Server': 'V-Restful/1.0'
        }
        body: '{"status": "ok"}'
    }
    
    headers := response.headers()
    assert headers['Content-Type'] == 'application/json; charset=utf-8'
    assert headers['Content-Length'] == '45'
    assert headers['Cache-Control'] == 'max-age=3600'
    assert headers['ETag'] == '"abc123"'
    assert headers['Last-Modified'] == 'Wed, 21 Oct 2015 07:28:00 GMT'
    assert headers['X-Request-ID'] == 'req-123'
    assert headers['X-Response-Time'] == '23ms'
    assert headers['Server'] == 'V-Restful/1.0'
}

fn test_response_body_methods_consistency() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"test": "data"}'
    }
    
    // Both methods should return the same result
    assert response.body(true) == response.body(false)
    assert response.body(true) == response.body
}

fn test_response_with_empty_string_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'text/plain'}
        body: ''
    }
    
    assert response.body(true) == ''
    assert response.body(false) == ''
}

fn test_response_with_whitespace_body() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'text/plain'}
        body: '   \n\t  '
    }
    
    assert response.body(true) == '   \n\t  '
    assert response.body(false) == '   \n\t  '
}

fn test_response_with_json_null() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: 'null'
    }
    
    assert response.body(true) == 'null'
}

fn test_response_with_json_boolean() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: 'true'
    }
    
    assert response.body(true) == 'true'
}

fn test_response_with_json_number() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '42'
    }
    
    assert response.body(true) == '42'
}

fn test_response_with_json_string() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '"hello world"'
    }
    
    assert response.body(true) == '"hello world"'
}

fn test_response_with_complex_json() {
    complex_json := '{"users": [{"id": 1, "name": "John", "active": true, "roles": ["admin", "user"]}, {"id": 2, "name": "Jane", "active": false, "roles": ["user"]}], "total": 2}'
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: complex_json
    }
    
    assert response.body(true) == complex_json
}

fn test_response_status_201_created() {
    response := restful.Response{
        status_code: 201
        headers: {
            'Location': '/api/items/123'
            'Content-Type': 'application/json'
        }
        body: '{"id": 123, "created": true}'
    }
    
    assert response.status_code() == 201
    assert response.headers()['Location'] == '/api/items/123'
}

fn test_response_status_202_accepted() {
    response := restful.Response{
        status_code: 202
        headers: {'Content-Type': 'application/json'}
        body: '{"message": "Request accepted"}'
    }
    
    assert response.status_code() == 202
}

fn test_response_status_400_bad_request() {
    response := restful.Response{
        status_code: 400
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Bad Request", "details": "Invalid input"}'
    }
    
    assert response.status_code() == 400
}

fn test_response_status_401_unauthorized() {
    response := restful.Response{
        status_code: 401
        headers: {
            'WWW-Authenticate': 'Bearer realm="api"'
        }
        body: '{"error": "Unauthorized"}'
    }
    
    assert response.status_code() == 401
}

fn test_response_status_403_forbidden() {
    response := restful.Response{
        status_code: 403
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Forbidden"}'
    }
    
    assert response.status_code() == 403
}

fn test_response_status_404_not_found() {
    response := restful.Response{
        status_code: 404
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Not Found"}'
    }
    
    assert response.status_code() == 404
}

fn test_response_status_409_conflict() {
    response := restful.Response{
        status_code: 409
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Conflict"}'
    }
    
    assert response.status_code() == 409
}

fn test_response_status_422_unprocessable() {
    response := restful.Response{
        status_code: 422
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Unprocessable Entity", "violations": {}}'
    }
    
    assert response.status_code() == 422
}

fn test_response_status_429_too_many_requests() {
    response := restful.Response{
        status_code: 429
        headers: {
            'Retry-After': '60'
            'X-RateLimit-Remaining': '0'
        }
        body: '{"error": "Too Many Requests"}'
    }
    
    assert response.status_code() == 429
}

fn test_response_status_500_internal_error() {
    response := restful.Response{
        status_code: 500
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Internal Server Error"}'
    }
    
    assert response.status_code() == 500
}

fn test_response_status_502_bad_gateway() {
    response := restful.Response{
        status_code: 502
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Bad Gateway"}'
    }
    
    assert response.status_code() == 502
}

fn test_response_status_503_service_unavailable() {
    response := restful.Response{
        status_code: 503
        headers: {
            'Retry-After': '30'
        }
        body: '{"error": "Service Unavailable"}'
    }
    
    assert response.status_code() == 503
}

fn test_response_status_504_gateway_timeout() {
    response := restful.Response{
        status_code: 504
        headers: {'Content-Type': 'application/json'}
        body: '{"error": "Gateway Timeout"}'
    }
    
    assert response.status_code() == 504
}

fn test_response_with_multiple_content_types() {
    test_cases := [
        'application/json',
        'application/xml',
        'text/plain',
        'text/html',
        'application/octet-stream',
        'multipart/form-data',
        'application/x-www-form-urlencoded'
    ]
    
    for content_type in test_cases {
        response := restful.Response{
            status_code: 200
            headers: {'Content-Type': content_type}
            body: 'test'
        }
        
        assert response.headers()['Content-Type'] == content_type
    }
}

fn test_response_with_very_long_header_value() {
    long_value := 'x'.repeat(1000)
    response := restful.Response{
        status_code: 200
        headers: {'X-Long-Header': long_value}
        body: 'OK'
    }
    
    assert response.headers()['X-Long-Header'] == long_value
}

fn test_response_with_special_header_characters() {
    response := restful.Response{
        status_code: 200
        headers: {
            'X-Special': 'value with spaces, commas, and "quotes"'
            'X-Unicode': 'café, naïve, 日本語'
        }
        body: 'OK'
    }
    
    headers := response.headers()
    assert headers['X-Special'] == 'value with spaces, commas, and "quotes"'
    assert headers['X-Unicode'] == 'café, naïve, 日本語'
}

fn test_response_body_with_emoji() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"emoji": "😀 🎉 🚀", "reaction": "👍"}'
    }
    
    assert response.body(true) == '{"emoji": "😀 🎉 🚀", "reaction": "👍"}'
}

fn test_response_with_all_status_codes() {
    status_codes := [
        100, 101, // 1xx informational
        200, 201, 202, 203, 204, 205, 206, // 2xx success
        300, 301, 302, 303, 304, 305, 307, 308, // 3xx redirection
        400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423, 424, 425, 426, 428, 429, 431, 451, // 4xx client error
        500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511 // 5xx server error
    ]
    
    for code in status_codes {
        response := restful.Response{
            status_code: code
            headers: map[string]string{}
            body: ''
        }
        
        assert response.status_code() == code
    }
}

fn test_response_structure_immutability() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"test": "data"}'
    }
    
    // Response fields should be accessible
    assert response.status_code == 200
    assert response.headers['Content-Type'] == 'application/json'
    assert response.body == '{"test": "data"}'
    
    // Methods should work
    assert response.status_code() == 200
    assert response.headers()['Content-Type'] == 'application/json'
    assert response.body(true) == '{"test": "data"}'
}

fn test_response_with_empty_headers() {
    response := restful.Response{
        status_code: 200
        headers: map[string]string{}
        body: 'OK'
    }
    
    assert response.headers().len == 0
}

fn test_response_with_single_header() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'text/plain'}
        body: 'OK'
    }
    
    assert response.headers().len == 1
    assert response.headers()['Content-Type'] == 'text/plain'
}

fn test_response_with_many_headers() {
    headers := {
        'A': '1'
        'B': '2'
        'C': '3'
        'D': '4'
        'E': '5'
        'F': '6'
        'G': '7'
        'H': '8'
        'I': '9'
        'J': '10'
    }
    
    response := restful.Response{
        status_code: 200
        headers: headers
        body: 'OK'
    }
    
    assert response.headers().len == 10
}

fn test_response_body_empty_string() {
    response := restful.Response{
        status_code: 200
        headers: map[string]string{}
        body: ''
    }
    
    assert response.body(true) == ''
    assert response.body(false) == ''
}

fn test_response_body_single_char() {
    response := restful.Response{
        status_code: 200
        headers: map[string]string{}
        body: 'x'
    }
    
    assert response.body(true) == 'x'
    assert response.body(false) == 'x'
}

fn test_response_body_unicode() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'text/plain; charset=utf-8'}
        body: 'Hello 世界 🌍 café'
    }
    
    assert response.body(true) == 'Hello 世界 🌍 café'
}

fn test_response_body_json_with_unicode() {
    response := restful.Response{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"message": "Hello 世界", "emoji": "🌍"}'
    }
    
    assert response.body(true) == '{"message": "Hello 世界", "emoji": "🌍"}'
}

fn test_response_with_all_fields() {
    response := restful.Response{
        status_code: 200
        headers: {
            'Content-Type': 'application/json'
            'X-Custom': 'value'
        }
        body: '{"data": "test"}'
    }
    
    // Test all fields
    assert response.status_code == 200
    assert response.headers['Content-Type'] == 'application/json'
    assert response.headers['X-Custom'] == 'value'
    assert response.body == '{"data": "test"}'
    
    // Test all methods
    assert response.status_code() == 200
    assert response.headers()['Content-Type'] == 'application/json'
    assert response.headers()['X-Custom'] == 'value'
    assert response.body(true) == '{"data": "test"}'
    assert response.body(false) == '{"data": "test"}'
}