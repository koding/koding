package client

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"socialapi/workers/presence"
	"strings"
	"testing"
)

func TestInternalValid(t *testing.T) {
	username, groupName := "testusername", "testgroupName"
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			t.Fatal("Method should be POST")
		}
		if r.URL.Path != presence.EndpointPresencePingPrivate {
			t.Fatalf("Expected url to be %s, got %s", presence.EndpointPresencePingPrivate, r.URL.Path)
		}
		d := &presence.PrivatePing{}
		if err := json.NewDecoder(r.Body).Decode(d); err != nil {
			t.Error(err.Error())
		}
		if d.GroupName != groupName {
			t.Fatalf("expected groupName %q, got %q", groupName, d.GroupName)
		}
		if d.Username != username {
			t.Fatalf("expected username %q, got %q", username, d.Username)
		}
	}))
	defer ts.Close()

	c := NewInternal(ts.URL)
	err := c.Ping(username, groupName)
	if err != nil {
		t.Error(err.Error())
	}
}

func TestInternalBadResponse(t *testing.T) {
	username, groupName := "testusername", "testgroupName"
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "error", 500)
	}))
	defer ts.Close()

	c := NewInternal(ts.URL)
	err := c.Ping(username, groupName)
	if err != nil && !strings.Contains(err.Error(), "bad response") {
		t.Errorf("excepted bad response error, got %s", err.Error())
	}
}

func TestInternalBadServer(t *testing.T) {
	username, groupName := "testusername", "testgroupName"
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	ts.Close()

	c := NewInternal(ts.URL)
	err := c.Ping(username, groupName)
	if err != nil && !strings.Contains(err.Error(), "refused") {
		t.Errorf("excepted conn refused error, got %s", err.Error())
	}
}

func TestInternalInvalidRequest(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	defer ts.Close()

	c := NewInternal(ts.URL)

	if err := c.Ping("", "groupName"); err == nil {
		t.Error("ping should fail when identifier is not given")
	}

	if err := c.Ping("username", ""); err == nil {
		t.Error("ping should fail when gorupName is not given")
	}
}

func TestInternalBadURL(t *testing.T) {
	defer func() {
		if out := recover(); out == nil {
			t.Errorf("NewInternal did not panic, but it should with bad url.")
		}
	}()

	NewInternal("bad url $^")
}
