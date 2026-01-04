module main

import restful
import json

// Мок для Node.js request
fn node_request(options restful.RequestOptions) !restful.RequestResponse {
    // В реальном приложении здесь будет вызов Node.js request
    // Это пример имитации
    return restful.RequestResponse{
        status_code: 200
        headers: {'Content-Type': 'application/json'}
        body: '{"_id": "1", "title": "Test"}'
    }
}

fn main() {
    backend := restful.request_backend(node_request)
    mut api := restful.restful('http://api.example.com', backend)
    api.identifier('_id')
    
    articles := api.all('articles')
    article := articles.get('1', map[string]string{}, map[string]string{})!
    data := article.data()
    println('Article: ${data['title']}')
}