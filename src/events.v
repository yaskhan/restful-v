module restful

pub type EventListener = fn (data EventData)

pub type EventData = RequestConfig | Response | IError

pub fn emit(listeners &map[string][]EventListener, event string, data EventData) {
    if event in *listeners {
        for listener in (*listeners)[event] {
            listener(data)
        }
    }
}