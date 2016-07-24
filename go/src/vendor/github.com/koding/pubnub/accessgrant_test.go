package pubnub

import (
	"os"
	"testing"
)

func newClientWithPAMSettings(id string) *ClientSettings {
	subscribeKey := os.Getenv("PUBNUB_PAM_SUBSCRIBE_KEY")
	publishKey := os.Getenv("PUBNUB_PAM_PUBLISH_KEY")
	secretKey := os.Getenv("PUBNUB_PAM_SECRET_KEY")

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

func TestGrantAccess(t *testing.T) {
	cs := newClientWithPAMSettings("tester")
	gc := NewPubNubClient(cs)
	defer func() {
		gc.Close()
	}()

	a := new(AuthSettings)
	a.ChannelName = "testme"
	a.Token = "123"
	a.CanWrite = true
	a.CanRead = true
	err := gc.Grant(a)

	if err != nil {
		t.Errorf("Expected nil but got error while granting access: %s", err)
	}

}

func TestGrantAccessWithGranter(t *testing.T) {
	cs := newClientWithPAMSettings("-1")
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
