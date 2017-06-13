package pubnub

import (
	"testing"
)

func TestGrantAccess(t *testing.T) {
	cs := newClientSettings("tester")
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
