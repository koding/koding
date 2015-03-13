package sender

type Sender interface {
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
	Email, Username string
}

const (
	TextBodyType BodyType = iota
	HtmlBodyType
)
