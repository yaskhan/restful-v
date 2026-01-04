module restful

pub type RequestInterceptor = fn (config RequestConfig) RequestConfig
pub type ResponseInterceptor = fn (response Response, config RequestConfig) Response
pub type ErrorInterceptor = fn (error IError, config RequestConfig) IError

pub struct Interceptors {
mut:
    request  []RequestInterceptor
    response []ResponseInterceptor
    error    []ErrorInterceptor
}