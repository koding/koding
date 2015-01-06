package pubnub

import (
	"os"
	"testing"
)

func newClientSettings(id string) *ClientSettings {
	subscribeKey := os.Getenv("PUBNUB_SUBSCRIBE_KEY")
	publishKey := os.Getenv("PUBNUB_PUBLISH_KEY")
	secretKey := os.Getenv("PUBNUB_SECRET_KEY")

	cs := new(ClientSettings)
	if id == "" {
		uuid := os.Getenv("PUBNUB_UUID")
		cs.ID = uuid
	}

	cs.SubscribeKey = subscribeKey
	cs.PublishKey = publishKey
	cs.SecretKey = secretKey

	return cs
}

func TestGrantAccessWithGranter(t *testing.T) {
	cs := newClientSettings("-1")
	ag := NewAccessGrant(NewAccessGrantOptions(), cs)

	a := new(AuthSettings)
	a.ChannelName = "testme"
	a.Token = "123"
	a.CanWrite = true
	a.CanRead = true
	err := ag.Grant(a)

	if err != nil {
		t.Errorf("Expected nil but got error while granting access: %s", err)
	}
}
