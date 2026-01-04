module restful

pub struct Response {
pub:
    status_code int
    headers     map[string]string
    body        string
}

pub fn (r &Response) body(hydrate bool) string {
    if !hydrate {
        return r.body
    }
    // For GET requests, entities are hydrated by the calling methods
    return r.body
}

pub fn (r &Response) headers() map[string]string {
    return r.headers
}

pub fn (r &Response) status_code() int {
    return r.status_code
}