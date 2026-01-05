module main

import restful
import x.json2 as json

fn main() {
	mut api := restful.restful('http://api.example.com', &restful.HttpBackend{})

	// Конфигурация
	api.header('AuthToken', 'my-token')
	api.identifier('_id')

	// Перехватчики
	api.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
		println('Request: ${config.method} ${config.url}')
		return config
	})

	api.add_response_interceptor(fn (response restful.Response, config restful.RequestConfig) restful.Response {
		println('Response: ${response.status_code}')
		return response
	})

	api.add_error_interceptor(fn (err IError, config restful.RequestConfig) IError {
		println('Error: ${err}')
		return err
	})

	// События
	api.on('error', fn (data restful.EventData) {
		if data is restful.ErrorEvent {
			println('Error event: ${data.err}')
		}
	})

	// Кастомный URL
	mut custom := api.custom('articles/beta', true)
	custom.get(map[string]string{}, map[string]string{})!

	// Работа с коллекцией
	mut articles := api.all('articles')
	articles.header('X-Custom', 'value')

	// POST с параметрами
	data := {
		'title': json.Any('Test')
	}
	params := {
		'debug': 'true'
	}
	headers := {
		'X-Request-ID': '123'
	}
	articles.post(data, params, headers)!
}
