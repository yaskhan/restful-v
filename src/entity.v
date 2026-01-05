module restful

import x.json2 as json

pub struct Entity {
mut:
    data   map[string]json.Any
    member &Member
}

pub fn (e &Entity) data() map[string]json.Any {
    return e.data
}

pub fn (e &Entity) id() string {
    return e.data[e.member.api.identifier] or { json.Any('') }.str()
}

pub fn (e &Entity) url() string {
    return e.member.url()
}

pub fn (mut e Entity) save() !Response {
    return e.member.put(e.data, map[string]string{}, map[string]string{})
}

pub fn (mut e Entity) delete() !Response {
    return e.member.delete(none, map[string]string{}, map[string]string{})
}

pub fn (e &Entity) one(name string, id string) &Member {
    return e.member.one(name, id)
}

pub fn (e &Entity) all(name string) &Collection {
    return e.member.all(name)
}

pub fn (e &Entity) custom(name string, is_relative bool) &Member {
    return e.member.custom(name, is_relative)
}

pub struct Collection {
pub mut:
    api             &API
    name            string
    parent          ?&Member
    headers         map[string]string
    interceptors    &Interceptors
    event_listeners &map[string][]EventListener
    identifier      string
}

pub fn (mut c Collection) get(id string, params map[string]string, headers map[string]string) !Entity {
    mut member := &Member{
        api:             c.api
        name:            c.name
        id:              id
        parent:          c.parent
        headers:         c.headers.clone()
        interceptors:    c.interceptors
        event_listeners: c.event_listeners
        identifier:      c.identifier
    }

    return member.get(params, headers)
}

pub fn (mut c Collection) get_all(params map[string]string, headers map[string]string) ![]Entity {
    url := c.url()

    mut final_headers := c.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    // Add API headers
    for k, v in c.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    config := RequestConfig{
        method:  'GET'
        url:     url
        headers: final_headers
        params:  params
    }

    // Emit request event
    emit(c.event_listeners, 'request', config)

    // Apply request interceptors
    mut final_config := config
    for interceptor in c.interceptors.request {
        final_config = interceptor(final_config)
    }

    // Execute request
    resp := c.api.backend.do(final_config)!

    // Apply response interceptors
    mut final_response := resp
    for interceptor in c.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    // Emit response event
    emit(c.event_listeners, 'response', final_response)

    // Parse body
    if final_response.status_code >= 200 && final_response.status_code < 400 {
        arr := json.decode[[]map[string]json.Any](final_response.body)!
        return arr.map(fn [c] (item map[string]json.Any) Entity {
            return Entity{
                data:   item
                member: &Member{
                    api:             c.api
                    name:            c.name
                    id:              item[c.identifier].str()
                    parent:          c.parent
                    headers:         c.headers.clone()
                    interceptors:    c.interceptors
                    event_listeners: c.event_listeners
                    identifier:      c.identifier
                }
            }
        })
    } else {
        // Apply error interceptors
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in c.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(c.event_listeners, 'error', err)
        return err
    }
}

pub fn (mut c Collection) post(data map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    url := c.url()

    mut final_headers := c.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    for k, v in c.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    json_data := json.encode(data)

    config := RequestConfig{
        method:  'POST'
        url:     url
        data:    json_data
        headers: final_headers
        params:  params
    }

    emit(c.event_listeners, 'request', config)

    mut final_config := config
    for interceptor in c.interceptors.request {
        final_config = interceptor(final_config)
    }

    resp := c.api.backend.do(final_config)!

    mut final_response := resp
    for interceptor in c.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    emit(c.event_listeners, 'response', final_response)

    if final_response.status_code >= 200 && final_response.status_code < 400 {
        return final_response
    } else {
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in c.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(c.event_listeners, 'error', err)
        return err
    }
}

pub fn (mut c Collection) put(id string, data map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    mut member := &Member{
        api:             c.api
        name:            c.name
        id:              id
        parent:          c.parent
        headers:         c.headers.clone()
        interceptors:    c.interceptors
        event_listeners: c.event_listeners
        identifier:      c.identifier
    }

    return member.put(data, params, headers)
}

pub fn (mut c Collection) patch(id string, data map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    mut member := &Member{
        api:             c.api
        name:            c.name
        id:              id
        parent:          c.parent
        headers:         c.headers.clone()
        interceptors:    c.interceptors
        event_listeners: c.event_listeners
        identifier:      c.identifier
    }

    return member.patch(data, params, headers)
}

pub fn (mut c Collection) delete(id string, data map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    mut member := &Member{
        api:             c.api
        name:            c.name
        id:              id
        parent:          c.parent
        headers:         c.headers.clone()
        interceptors:    c.interceptors
        event_listeners: c.event_listeners
        identifier:      c.identifier
    }

    return member.delete(data, params, headers)
}

pub fn (mut c Collection) head(id string, params map[string]string, headers map[string]string) !Response {
    mut member := &Member{
        api:             c.api
        name:            c.name
        id:              id
        parent:          c.parent
        headers:         c.headers.clone()
        interceptors:    c.interceptors
        event_listeners: c.event_listeners
        identifier:      c.identifier
    }

    return member.head(params, headers)
}

pub fn (mut c Collection) one(name string, id string) &Member {
    parent_member := &Member{
        api:             c.api
        name:            c.name
        id:              id
        parent:          c.parent
        headers:         c.headers.clone()
        interceptors:    c.interceptors
        event_listeners: c.event_listeners
        identifier:      c.identifier
    }

    return parent_member.one(name, '')
}

pub fn (mut c Collection) custom(name string, is_relative bool) &Member {
    url := if is_relative { '${c.url()}/${name}' } else { name }
    return &Member{
        api:             c.api
        name:            name
        id:              ''
        parent:          none
        headers:         c.headers.clone()
        interceptors:    c.interceptors
        event_listeners: c.event_listeners
        identifier:      c.identifier
        custom_url:      url
    }
}

pub fn (mut c Collection) header(name string, value string) {
    c.headers[name] = value
}

pub fn (c &Collection) headers() map[string]string {
    return c.headers
}

pub fn (mut c Collection) on(event string, listener EventListener) {
    unsafe {
        mut arr := (*c.event_listeners)[event] or { []EventListener{} }
        arr << listener
        (*c.event_listeners)[event] = arr
    }
}

pub fn (mut c Collection) once(event string, listener EventListener) {
    mut called := false
    wrapped := fn [listener, mut called] (data EventData) {
        if called {
            return
        }
        called = true
        listener(data)
    }

    unsafe {
        mut arr := (*c.event_listeners)[event] or { []EventListener{} }
        arr << wrapped
        (*c.event_listeners)[event] = arr
    }
}

pub fn (mut c Collection) add_request_interceptor(interceptor RequestInterceptor) {
    c.interceptors.request << interceptor
}

pub fn (mut c Collection) add_response_interceptor(interceptor ResponseInterceptor) {
    c.interceptors.response << interceptor
}

pub fn (mut c Collection) add_error_interceptor(interceptor ErrorInterceptor) {
    c.interceptors.error << interceptor
}

pub fn (mut c Collection) identifier(id string) {
    c.identifier = id
}

pub fn (c &Collection) url() string {
    base := c.api.base_url
    name := c.name

    if c.parent == none {
        return '${base}/${name}'
    }

    parent := c.parent or { return '${base}/${name}' }
    return '${parent.url()}/${name}'
}

pub struct Member {
mut:
    api             &API
    name            string
    id              string
    parent          ?&Member
    headers         map[string]string
    interceptors    &Interceptors
    event_listeners &map[string][]EventListener
    identifier      string
    custom_url      string
}

pub fn (mut m Member) get(params map[string]string, headers map[string]string) !Entity {
    url := m.url()

    mut final_headers := m.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    for k, v in m.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    config := RequestConfig{
        method:  'GET'
        url:     url
        headers: final_headers
        params:  params
    }

    emit(m.event_listeners, 'request', config)

    mut final_config := config
    for interceptor in m.interceptors.request {
        final_config = interceptor(final_config)
    }

    resp := m.api.backend.do(final_config)!

    mut final_response := resp
    for interceptor in m.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    emit(m.event_listeners, 'response', final_response)

    if final_response.status_code >= 200 && final_response.status_code < 400 {
        data := json.decode[map[string]json.Any](final_response.body)!
        return Entity{
            data:   data
            member: &m
        }
    } else {
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in m.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(m.event_listeners, 'error', err)
        return err
    }
}

pub fn (mut m Member) post(data map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    url := m.url()

    mut final_headers := m.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    for k, v in m.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    json_data := json.encode(data)

    config := RequestConfig{
        method:  'POST'
        url:     url
        data:    json_data
        headers: final_headers
        params:  params
    }

    emit(m.event_listeners, 'request', config)

    mut final_config := config
    for interceptor in m.interceptors.request {
        final_config = interceptor(final_config)
    }

    resp := m.api.backend.do(final_config)!

    mut final_response := resp
    for interceptor in m.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    emit(m.event_listeners, 'response', final_response)

    if final_response.status_code >= 200 && final_response.status_code < 400 {
        return final_response
    } else {
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in m.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(m.event_listeners, 'error', err)
        return err
    }
}

pub fn (mut m Member) put(data map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    url := m.url()

    mut final_headers := m.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    for k, v in m.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    json_data := json.encode(data)

    config := RequestConfig{
        method:  'PUT'
        url:     url
        data:    json_data
        headers: final_headers
        params:  params
    }

    emit(m.event_listeners, 'request', config)

    mut final_config := config
    for interceptor in m.interceptors.request {
        final_config = interceptor(final_config)
    }

    resp := m.api.backend.do(final_config)!

    mut final_response := resp
    for interceptor in m.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    emit(m.event_listeners, 'response', final_response)

    if final_response.status_code >= 200 && final_response.status_code < 400 {
        return final_response
    } else {
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in m.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(m.event_listeners, 'error', err)
        return err
    }
}

pub fn (mut m Member) patch(data map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    url := m.url()

    mut final_headers := m.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    for k, v in m.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    json_data := json.encode(data)

    config := RequestConfig{
        method:  'PATCH'
        url:     url
        data:    json_data
        headers: final_headers
        params:  params
    }

    emit(m.event_listeners, 'request', config)

    mut final_config := config
    for interceptor in m.interceptors.request {
        final_config = interceptor(final_config)
    }

    resp := m.api.backend.do(final_config)!

    mut final_response := resp
    for interceptor in m.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    emit(m.event_listeners, 'response', final_response)

    if final_response.status_code >= 200 && final_response.status_code < 400 {
        return final_response
    } else {
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in m.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(m.event_listeners, 'error', err)
        return err
    }
}

pub fn (mut m Member) delete(data ?map[string]json.Any, params map[string]string, headers map[string]string) !Response {
    url := m.url()

    mut final_headers := m.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    for k, v in m.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    var_data := if data != none { json.encode(data) } else { '' }

    config := RequestConfig{
        method:  'DELETE'
        url:     url
        data:    var_data
        headers: final_headers
        params:  params
    }

    emit(m.event_listeners, 'request', config)

    mut final_config := config
    for interceptor in m.interceptors.request {
        final_config = interceptor(final_config)
    }

    resp := m.api.backend.do(final_config)!

    mut final_response := resp
    for interceptor in m.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    emit(m.event_listeners, 'response', final_response)

    if final_response.status_code >= 200 && final_response.status_code < 400 {
        return final_response
    } else {
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in m.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(m.event_listeners, 'error', err)
        return err
    }
}

pub fn (mut m Member) head(params map[string]string, headers map[string]string) !Response {
    url := m.url()

    mut final_headers := m.headers.clone()
    for k, v in headers {
        final_headers[k] = v
    }

    for k, v in m.api.headers {
        if k !in final_headers {
            final_headers[k] = v
        }
    }

    config := RequestConfig{
        method:  'HEAD'
        url:     url
        headers: final_headers
        params:  params
    }

    emit(m.event_listeners, 'request', config)

    mut final_config := config
    for interceptor in m.interceptors.request {
        final_config = interceptor(final_config)
    }

    resp := m.api.backend.do(final_config)!

    mut final_response := resp
    for interceptor in m.interceptors.response {
        final_response = interceptor(final_response, final_config)
    }

    emit(m.event_listeners, 'response', final_response)

    if final_response.status_code >= 200 && final_response.status_code < 400 {
        return final_response
    } else {
        mut err := error('HTTP ${final_response.status_code}')
        for interceptor in m.interceptors.error {
            err = interceptor(err, final_config)
        }
        emit(m.event_listeners, 'error', err)
        return err
    }
}

pub fn (m &Member) one(name string, id string) &Member {
    return &Member{
        api:             m.api
        name:            name
        id:              id
        parent:          unsafe { m }
        headers:         m.headers.clone()
        interceptors:    m.interceptors
        event_listeners: m.event_listeners
        identifier:      m.identifier
    }
}

pub fn (m &Member) all(name string) &Collection {
    return &Collection{
        api:             m.api
        name:            name
        parent:          unsafe { m }
        headers:         m.headers.clone()
        interceptors:    m.interceptors
        event_listeners: m.event_listeners
        identifier:      m.identifier
    }
}

pub fn (m &Member) custom(name string, is_relative bool) &Member {
    url := if is_relative { '${m.url()}/${name}' } else { name }
    return &Member{
        api:             m.api
        name:            name
        id:              ''
        parent:          unsafe { m }
        headers:         m.headers.clone()
        interceptors:    m.interceptors
        event_listeners: m.event_listeners
        identifier:      m.identifier
        custom_url:      url
    }
}

pub fn (mut m Member) header(name string, value string) {
    m.headers[name] = value
}

pub fn (m &Member) headers() map[string]string {
    return m.headers
}

pub fn (mut m Member) on(event string, listener EventListener) {
    unsafe {
        mut arr := (*m.event_listeners)[event] or { []EventListener{} }
        arr << listener
        (*m.event_listeners)[event] = arr
    }
}

pub fn (mut m Member) once(event string, listener EventListener) {
    mut called := false
    wrapped := fn [listener, mut called] (data EventData) {
        if called {
            return
        }
        called = true
        listener(data)
    }

    unsafe {
        mut arr := (*m.event_listeners)[event] or { []EventListener{} }
        arr << wrapped
        (*m.event_listeners)[event] = arr
    }
}

pub fn (mut m Member) add_request_interceptor(interceptor RequestInterceptor) {
    m.interceptors.request << interceptor
}

pub fn (mut m Member) add_response_interceptor(interceptor ResponseInterceptor) {
    m.interceptors.response << interceptor
}

pub fn (mut m Member) add_error_interceptor(interceptor ErrorInterceptor) {
    m.interceptors.error << interceptor
}

pub fn (mut m Member) identifier(id string) {
    m.identifier = id
}

pub fn (m &Member) url() string {
    if m.custom_url != '' {
        return m.custom_url
    }

    base := m.api.base_url

    if m.parent == none {
        if m.id == '' {
            return '${base}/${m.name}'
        }
        return '${base}/${m.name}/${m.id}'
    }

    parent := m.parent or { return '${base}/${m.name}/${m.id}' }
    parent_url := parent.url()
    if m.id == '' {
        return '${parent_url}/${m.name}'
    }
    return '${parent_url}/${m.name}/${m.id}'
}
