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
	Name       string
	User       *User
	Body       *Body
	Properties map[string]interface{}
}

type BodyType int

type Body struct {
	Type    BodyType
	Content string
}

type User struct {
	Email    string
	Username string
}
