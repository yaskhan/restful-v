module restful

import net.http
import json

pub struct API {
mut:
	base_url        string
	backend         Backend
	headers         map[string]string
	identifier      string = 'id'
	interceptors    Interceptors
	event_listeners map[string][]EventListener
}

pub fn restful(base_url string, backend Backend) &API {
	return &API{
		base_url:        base_url
		backend:         backend
		headers:         map[string]string{}
		interceptors:    Interceptors{}
		event_listeners: map[string][]EventListener{}
	}
}

pub fn (mut a API) all(name string) &Collection {
	return &Collection{
		api:             a
		name:            name
		parent:          none
		headers:         map[string]string{}
		interceptors:    &a.interceptors
		event_listeners: &a.event_listeners
	}
}

pub fn (mut a API) one(name string, id string) &Member {
	return &Member{
		api:             a
		name:            name
		id:              id
		parent:          none
		headers:         map[string]string{}
		interceptors:    &a.interceptors
		event_listeners: &a.event_listeners
	}
}

pub fn (mut a API) custom(name string, is_relative bool) &Member {
	url := if is_relative { '${a.base_url}/${name}' } else { name }
	return &Member{
		api:             a
		name:            name
		id:              ''
		parent:          none
		headers:         map[string]string{}
		interceptors:    &a.interceptors
		event_listeners: &a.event_listeners
		custom_url:      url
	}
}

pub fn (mut a API) header(name string, value string) {
	a.headers[name] = value
}

pub fn (a &API) headers() map[string]string {
	return a.headers
}

pub fn (mut a API) identifier(id string) {
	a.identifier = id
}

pub fn (mut a API) on(event string, listener EventListener) {
	a.event_listeners[event] << listener
}

pub fn (mut a API) once(event string, listener EventListener) {
	wrapped := fn [listener] (data EventData) {
		listener(data)
		// Remove after first call would be handled in emit
	}
	a.event_listeners[event] << wrapped
}

pub fn (mut a API) add_request_interceptor(interceptor RequestInterceptor) {
	a.interceptors.request << interceptor
}

pub fn (mut a API) add_response_interceptor(interceptor ResponseInterceptor) {
	a.interceptors.response << interceptor
}

pub fn (mut a API) add_error_interceptor(interceptor ErrorInterceptor) {
	a.interceptors.error << interceptor
}
