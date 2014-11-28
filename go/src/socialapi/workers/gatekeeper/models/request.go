package models

// Channel request is used for channel authentication
type ChannelRequest struct {
	Request
}

// Message request is used for pushing events
type MessageRequest struct {
	EventName string      `json:"eventName"`
	Body      interface{} `json:"body"`
	Request
}

// General purpose Request struct
type Request struct {
	Name  string `json:"name"`
	Group string `json:"group"`
	Type  string `json:"typeConstant"`
}
