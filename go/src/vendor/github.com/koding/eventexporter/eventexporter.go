package eventexporter

import "time"

const (
	TextBodyType BodyType = iota
	HtmlBodyType
)

// Exporter is the interface to export events to a 3rd party service.
// Currently third party services: SegementIO and Sendgrid are implemented.
type Exporter interface {
	Send(*Event) error
	Name() string
	Close() error
}

// Event represent an action in time that is done by an user, has body
// and optionally some properties.
type Event struct {
	Name       string                 // name of event
	User       *User                  // user who did event
	Body       *Body                  // body of event; text or html
	Properties map[string]interface{} // any additional properties
	Context    map[string]interface{} // any additional context

	Count    int64         // count of the event
	Duration time.Duration // duration of the event
	// Publish this events to only whitelisted upstreams
	WhitelistedUpstreams []string
}

type BodyType int

// Body is used to send text or html of event directly to 3rd party.
// Ideally none of html should exist in codebase so it's easy to change,
// however legacy html code still exists.
type Body struct {
	Type    BodyType // text or html
	Content string
}

type User struct {
	Email    string
	Username string
}
