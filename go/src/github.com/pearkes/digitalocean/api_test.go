package digitalocean

import (
	"os"
	"testing"

	. "github.com/motain/gocheck"
	"github.com/pearkes/digitalocean/testutil"
)

type S struct {
	client *Client
}

var _ = Suite(&S{})

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *C) {
	testServer.Start()
	var err error
	s.client, err = NewClient("foobar")
	s.client.URL = "http://localhost:4444"
	if err != nil {
		panic(err)
	}
}

func (s *S) TearDownTest(c *C) {
	testServer.Flush()
}

func makeClient(t *testing.T) *Client {
	client, err := NewClient("foobartoken")

	if err != nil {
		t.Fatalf("err: %v", err)
	}

	if client.Token != "foobartoken" {
		t.Fatalf("token not set on client: %s", client.Token)
	}

	return client
}

func Test_NewClient_env(t *testing.T) {
	os.Setenv("DIGITALOCEAN_TOKEN", "bar")
	client, err := NewClient("")

	if err != nil {
		t.Fatalf("err: %v", err)
	}

	if client.Token != "bar" {
		t.Fatalf("token not set on client: %s", client.Token)
	}
}

func TestClient_NewRequest(t *testing.T) {
	c := makeClient(t)

	body := map[string]string{
		"foo": "bar",
		"baz": "bar",
	}

	req, err := c.NewRequest(body, "POST", "/bar")
	if err != nil {
		t.Fatalf("bad: %v", err)
	}

	if req.URL.String() != "https://api.digitalocean.com/v2/bar" {
		t.Fatalf("bad base url: %v", req.URL.String())
	}

	if req.Header.Get("Authorization") != "Bearer foobartoken" {
		t.Fatalf("bad auth header: %v", req.Header)
	}

	if req.Method != "POST" {
		t.Fatalf("bad method: %v", req.Method)
	}
}
