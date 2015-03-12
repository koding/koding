package sender

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
	Html BodyType = iota
	Text
)
