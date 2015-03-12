package sender

type Event struct {
	Name       string
	User       user
	Body       body
	Properties map[string]interface{}
}

type bodyType int

type body struct {
	Type    bodyType
	Content string
}

type user struct {
	Email, Username string
}

const (
	Html bodyType = iota
	Text
)
