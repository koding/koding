package sendgrid

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
)

const (
	APIUser     = "API_USER"
	APIPassword = "API_PASSWORD"
)

func TestNewSendGridClient(t *testing.T) {
	client := NewSendGridClient(APIUser, APIPassword)
	if client == nil {
		t.Error("NewSendGridClient should never return nil")
	}
}

func TestSend(t *testing.T) {
	fakeServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "{\"message\": \"success\"}")
	}))
	defer fakeServer.Close()
	m := NewMail()
	client := NewSendGridClient(APIUser, APIPassword)
	client.APIMail = fakeServer.URL
	m.AddTo("Test! <test@email.com>")
	m.SetSubject("Test")
	m.SetText("Text")
	client.Send(m)
}
