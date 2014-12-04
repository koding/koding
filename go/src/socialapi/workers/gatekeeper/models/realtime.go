package models

type Realtime interface {
	Authenticate(req *ChannelRequest) error
	Push(req PushMessage) error
}
