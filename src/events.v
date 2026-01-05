module restful

pub type EventListener = fn (data EventData)

pub struct ErrorEvent {
pub:
    err IError
}

pub type EventData = RequestConfig | Response | ErrorEvent

pub fn emit(listeners &map[string][]EventListener, event string, data EventData) {
    unsafe {
        if event in *listeners {
            for listener in (*listeners)[event] {
                listener(data)
            }
        }
    }
}
