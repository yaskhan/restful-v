module restful

pub struct Response {
pub mut:
	status_code int
	headers     map[string]string
	body        string
}

pub fn (r &Response) status() int {
	return r.status_code
}

pub fn (r &Response) status_code() int {
	return r.status_code
}

pub fn (r &Response) headers() map[string]string {
	return r.headers
}

pub fn (r &Response) body(hydration bool) string {
	return r.body
}
