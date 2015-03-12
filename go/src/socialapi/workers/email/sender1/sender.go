package sender

type Sender interface {
	Send(*Event) error
}
