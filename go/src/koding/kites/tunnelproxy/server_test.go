package tunnelproxy_test

import (
	"net"
	"net/http"
	"net/url"
	"sync"
	"testing"

	"github.com/gorilla/mux"
)

type Listener struct {
	sync.WaitGroup
	sync.Once
	net.Listener
}

func Listen(network, addr string) (*Listener, error) {
	l, err := net.Listen(network, addr)
	if err != nil {
		return nil, err
	}
	ll := &Listener{Listener: l}
	ll.Add(1)
	return ll, nil
}

func (l *Listener) Accept() (net.Conn, error) {
	l.Do(l.Done)
	return l.Listener.Accept()
}

type Counter struct {
	mu sync.Mutex
	m  map[string]int
}

func NewCounter() *Counter {
	return &Counter{
		m: make(map[string]int),
	}
}

func (c *Counter) Method(name string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		c.mu.Lock()
		c.m[name]++
		c.mu.Unlock()

		w.WriteHeader(200)
	}
}

func (c *Counter) Count(name string) int {
	c.mu.Lock()
	defer c.mu.Unlock()

	return c.m[name]
}

func TestGorillaMux(t *testing.T) {
	c := NewCounter()
	m := mux.NewRouter()

	if err := m.Handle("/-/discover/{service}", c.Method("discover")).GetError(); err != nil {
		t.Fatal(err)
	}

	if err := m.Handle(`/{rest:.?$|[^\/].+|\/[^-].+|\/-[^\/].*}`, c.Method("rest")).GetError(); err != nil {
		t.Fatal(err)
	}

	l, err := Listen("tcp", ":0")
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()

	go http.Serve(l, m)

	l.Wait()

	cases := []struct {
		path   string
		method string
	}{
		{"/-/discover/abc", "discover"},
		{"/-/discover/a", "discover"},
		{"/-/discover/b", "discover"},
		{"/abc", "rest"},
		{"/a", "rest"},
		{"/", "rest"},
	}

	for i, cas := range cases {
		u := &url.URL{
			Scheme: "http",
			Host:   l.Addr().String(),
			Path:   cas.path,
		}

		before := c.Count(cas.method)

		resp, err := http.Get(u.String())
		if err != nil {
			t.Errorf("%d: Get()=%s", i, err)
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			t.Errorf("%d: got %d, want 200", i, resp.StatusCode)
			continue
		}

		after := c.Count(cas.method)

		if before+1 != after {
			t.Errorf("%d: got %d, want %d", after, before+1)
		}
	}
}
