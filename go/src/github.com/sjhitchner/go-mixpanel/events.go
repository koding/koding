package mixpanel

import (
	"net"
	"time"
)

const (
	MIXPANEL_EVENT_TOKEN       = "token"
	MIXPANEL_EVENT_DISTINCT_ID = "distinct_id"
	MIXPANEL_EVENT_TIME        = "time"
	MIXPANEL_EVENT_IP          = "ip"
)

// Event Struct used to create events
// {
//     "event": "Signed Up",
//     "properties": {
//         // "distinct_id" and "token" are
//         // special properties, described below.
//         "distinct_id": "13793",
//         "token": "e3bc4100330c35722740fb8c6f5abddc",
//         "Referred By": "Friend"
//     }
// }
type Event struct {
	Name       string                 `json:"event"`
	Properties map[string]interface{} `json:"properties"`
}

// TODO implement chaining api
func NewEvent(name string) *Event {
	return &Event{
		name,
		make(map[string]interface{}),
	}
}

func (e *Event) setToken(token string) {
	e.Properties[MIXPANEL_EVENT_TOKEN] = token
}

func (e *Event) SetTime(t time.Time) {
	e.Properties[MIXPANEL_EVENT_TIME] = t.UTC().Unix()
}

func (e *Event) SetDistinctId(id string) {
	e.Properties[MIXPANEL_EVENT_DISTINCT_ID] = id
}

func (e *Event) SetIp(ip net.IP) {
	e.Properties[MIXPANEL_EVENT_IP] = ip.String()
}

func (e *Event) AddProperty(key string, value interface{}) {
	switch t := value.(type) {
	case time.Time:
		e.Properties[key] = time2String(t)
	default:
		e.Properties[key] = value
	}
}
