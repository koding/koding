package eventexporter

const (
	TextBodyType BodyType = iota
	HtmlBodyType
)

// Exporter is the interface to export events to a 3rd party service.
// Currently third party services: SegementIO and Sendgrid are implemented.
// LogExporter also implements the interface, meant for testing purposes.
type Exporter interface {
	Send(*Event) error
}

type Event struct {
	Name       string                 // name of event
	User       *User                  // user who did event
	Body       *Body                  // body of event; text or html
	Properties map[string]interface{} // any additional properties
}

type BodyType int

type Body struct {
	Type    BodyType // text or html
	Content string
}

type User struct {
	Email    string
	Username string
}
