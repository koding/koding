package integration

import (
	"testing"

	"github.com/koding/integration/services"
	"github.com/koding/logging"
)

var testRootPath = "http://lvh.me:8090"

func TestValidate(t *testing.T) {

	l := logging.NewLogger("test")
	h := NewHandler(l, "https://koding.com")

	err := h.validate("", "")
	if err != ErrTokenNotSet {
		t.Errorf("expected '%s' error, but got '%s'", ErrTokenNotSet, err)
	}

	err = h.validate("", "tokentome")
	if err != ErrNameNotSet {
		t.Errorf("expected '%s' errors, but got '%s'", ErrNameNotSet, err)
	}
}

func TestVerificationIntegration(t *testing.T) {
	l := logging.NewLogger("test")
	h := NewHandler(l, testRootPath)

	// test invalid integration service
	err := h.verifyService("testigme")
	if err == nil && err.Error() != ErrContentNotFound.Error() {
		t.Fatalf("expected '%s' error but got '%v'", ErrContentNotFound)
	}

	// test valid integration service
	err = h.verifyService("iterable")
	if err != nil {
		t.Errorf("expected nil but got '%s' error", err)
	}
}

func TestFetchBotChannelIntegration(t *testing.T) {

	l := logging.NewLogger("test")
	h := NewHandler(l, testRootPath)

	// test unknown user case
	_, err := h.fetchBotChannelId("1qa2wxs3er4", "token")
	if err == nil || err.Error() != ErrInvalidToken.Error() {
		t.Fatalf("expected '%s' error but got '%v'", ErrInvalidToken, err)
	}

	// test invalid token case
	_, err = h.fetchBotChannelId("floydpepper", "201b81e3-02d8-42d5-9828-a6165bbd7893")
	if err == nil || err.Error() != ErrIntegrationNotFound.Error() {
		t.Fatalf("expected '%s' error but got '%s'", ErrIntegrationNotFound, err)
	}

	// test valid username and token pair
	id, err := h.fetchBotChannelId("floydpepper", "validtoken")
	if err != nil {
		t.Errorf("expected nil but got '%s'", err)
	}

	if id != 42 {
		t.Errorf("expected 42 as channel id but got %d", id)
	}
}

func TestPrepareRequest(t *testing.T) {
	l := logging.NewLogger("test")
	h := NewHandler(l, testRootPath)
	si := &services.ServiceInput{}
	groupName := "electricmayhem"
	si.SetKey("groupName", groupName)

	pr, err := h.prepareRequest("iterable", "token", si)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if pr.GroupName != groupName {
		t.Errorf("expected '%s' as group name but got '%s'", groupName, pr.GroupName)
	}

	if pr.ChannelId != 0 {
		t.Errorf("unexpected channel id: %d", pr.ChannelId)
	}

	si.SetKey("username", "floydpepper")
	pr, err = h.prepareRequest("iterable", "validtoken", si)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if pr.ChannelId != 42 {
		t.Errorf("expected 42 as channel id but got %d", pr.ChannelId)
	}
}

func TestPush(t *testing.T) {
	l := logging.NewLogger("test")
	h := NewHandler(l, testRootPath)
	pr := &PushRequest{}
	token := ""

	err := h.push(token, pr)
	if err == nil || err.Error() != ErrTokenNotSet.Error() {
		t.Errorf("expected '%s' but got '%v'", ErrTokenNotSet, err)
	}

	token = "0bc752e0-03c5-4f29-8776-328e2e88e226"
	err = h.push(token, pr)
	if err == nil || err.Error() != ErrBodyNotSet.Error() {
		t.Errorf("expected '%s' but got '%v'", ErrBodyNotSet, err)
	}
	pr.Body = "bodyshape"

	err = h.push(token, pr)
	if err == nil || err.Error() != ErrChannelNotSet.Error() {
		t.Errorf("expected '%s' but got '%v'", ErrChannelNotSet, err)
	}

	pr.ChannelId = 3
	err = h.push(token, pr)
	if err != nil {
		t.Errorf("unexpected error: '%s'", err)
	}

}
