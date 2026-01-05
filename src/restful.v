module restful

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
        interceptors:    unsafe { &a.interceptors }
        event_listeners: unsafe { &a.event_listeners }
    }
}

pub fn (mut a API) one(name string, id string) &Member {
    return &Member{
        api:             a
        name:            name
        id:              id
        parent:          none
        headers:         map[string]string{}
        interceptors:    unsafe { &a.interceptors }
        event_listeners: unsafe { &a.event_listeners }
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
        interceptors:    unsafe { &a.interceptors }
        event_listeners: unsafe { &a.event_listeners }
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
    unsafe {
        mut arr := a.event_listeners[event] or { []EventListener{} }
        arr << listener
        a.event_listeners[event] = arr
    }
}

pub fn (mut a API) once(event string, listener EventListener) {
    mut called := false
    wrapped := fn [listener, mut called] (data EventData) {
        if called {
            return
        }
        called = true
        listener(data)
    }
    unsafe {
        mut arr := a.event_listeners[event] or { []EventListener{} }
        arr << wrapped
        a.event_listeners[event] = arr
    }
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
