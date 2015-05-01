package dnsimple

import (
	"testing"
)

func makeClient(t *testing.T) *Client {
	client, err := NewClient("foobaremail", "foobartoken")

	if err != nil {
		t.Fatalf("err: %v", err)
	}

	if client.Token != "foobartoken" {
		t.Fatalf("token not set on client: %s", client.Token)
	}

	return client
}

func TestClient_NewRequest(t *testing.T) {
	c := makeClient(t)

	body := map[string]interface{}{
		"foo": "bar",
		"baz": "bar",
	}
	req, err := c.NewRequest(body, "POST", "/bar")
	if err != nil {
		t.Fatalf("bad: %v", err)
	}

	if req.URL.String() != "https://api.dnsimple.com/v1/bar" {
		t.Fatalf("bad base url: %v", req.URL.String())
	}

	if req.Header.Get("X-DNSimple-Token") != "foobaremail:foobartoken" {
		t.Fatalf("bad auth header: %v", req.Header)
	}

	if req.Method != "POST" {
		t.Fatalf("bad method: %v", req.Method)
	}
}
