package webhook

import (
	"bytes"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"reflect"
	"sort"
	"testing"

	"golang.org/x/net/context"
)

const secret = "dupa.8"

type Foo struct{}

func (Foo) All(string, interface{}) {}
func (Foo) Ping(*PingEvent)         {}
func (Foo) Err() error              { return nil }

type Bar struct{}

func (Bar) Create(*CreateEvent) {}
func (Bar) Gist(*GistEvent)     {}
func (Bar) Push(*PushEvent)     {}
func (Bar) push(*PushEvent)     {}
func (Bar) Other()              {}

type Baz struct{}

func (Baz) All(string, interface{})              {}
func (Baz) Delete(*DeleteEvent)                  {}
func (Baz) ForkApply(*ForkApplyEvent)            {}
func (Baz) Gollum(*GollumEvent)                  {}
func (Baz) gollum(*GollumEvent)                  {}
func (Baz) Create(context.Context, *CreateEvent) {}
func (Baz) Add(int, int) int                     { return 0 }

func TestPayloadMethods(t *testing.T) {
	cases := [...]struct {
		rcvr   interface{}
		events []string
	}{
		// i=0
		{
			Foo{},
			[]string{"*", "ping"},
		},
		// i=1
		{
			Bar{},
			[]string{"create", "gist", "push"},
		},
		// i=2
		{
			Baz{},
			[]string{"*", "create", "delete", "fork_apply", "gollum"},
		},
	}
	for i, cas := range cases {
		m := payloadMethods(reflect.TypeOf(cas.rcvr))
		events := make([]string, 0, len(m))
		for k := range m {
			events = append(events, k)
		}
		sort.StringSlice(events).Sort()
		if !reflect.DeepEqual(events, cas.events) {
			t.Errorf("want events=%v; got %v (i=%d)", cas.events, events, i)
		}
	}
}

func testHandler(t *testing.T, handler http.Handler) {
	ts := httptest.NewServer(handler)
	defer ts.Close()

	for event := range payloads {
		body, err := ioutil.ReadFile(filepath.Join("testdata", event+".json"))
		if err != nil {
			t.Fatal(err)
		}
		req, err := http.NewRequest("POST", ts.URL, bytes.NewReader(body))
		if err != nil {
			t.Fatal(err)
		}
		req.Header.Set("X-GitHub-Event", event)
		req.Header.Set("X-Hub-Signature", "sha1="+hmacHexDigest(secret, body))
		req.Header.Set("Content-Type", "application/json; charset=utf-8")
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			t.Errorf("Do(req)=%v (event=%s)", err, event)
		}
		if resp.StatusCode != 200 {
			t.Errorf("want StatusCode=200; got %d (event=%s)", resp.StatusCode, event)
		}
	}
}

func TestHandlerWithDetail(t *testing.T) {
	h := DetailHandler{}
	testHandler(t, New(secret, h))
	for event := range payloads {
		if h[event] != 1 {
			t.Errorf("want h[%s]=1; got %d", event, h[event])
		}
	}
}

func TestHandlerWithBlanket(t *testing.T) {
	h := BlanketHandler{}
	testHandler(t, New(secret, h))
	for event := range payloads {
		if h[event] != 1 {
			t.Errorf("want h[%s]=1; got %d", event, h[event])
		}
	}
}
