package tigertonic

import (
	"fmt"
	"net"
	"net/http"
	"testing"
	"time"
)

func TestServerCATLS(t *testing.T) {
	s, err := NewTLSServer("", "test.crt", "test.key", NotFoundHandler{})
	if nil != err {
		t.Fatal(err)
	}
	s.CA("test.crt")
	if nil == s.TLSConfig.Certificates || 1 != len(s.TLSConfig.Certificates) {
		t.Fatal("no Certificates")
	}
	if nil == s.TLSConfig.RootCAs || 1 != len(s.TLSConfig.RootCAs.Subjects()) {
		t.Fatal("no RootCAs")
	}
}

func TestServerGracefulStop(t *testing.T) {
	chT := make(chan time.Time, 1)
	s := NewServer(
		"127.0.0.1:0",
		http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			time.Sleep(2 * time.Millisecond)
			w.WriteHeader(http.StatusNoContent)
			chT <- time.Now()
		}),
	)
	l, err := net.Listen("tcp", s.Addr)
	if nil != err {
		t.Fatal(err)
	}
	go s.Serve(l)
	chR := make(chan *http.Response, 1)
	go func() {
		rs, err := http.Get(fmt.Sprintf("http://%s", l.Addr()))
		if nil != err {
			t.Fatal(err)
		}
		chR <- rs
	}()
	time.Sleep(time.Millisecond)
	s.Close()
	now := time.Now()
	then := <-chT
	if now.Before(then) {
		t.Fatal(now, "before", then)
	}
	if then.Add(10 * time.Millisecond).Before(now) {
		t.Fatal("connection not closed quickly")
	}
	rs := <-chR
	if http.StatusNoContent != rs.StatusCode {
		t.Fatal(rs)
	}
	if _, err := http.Get(fmt.Sprintf("http://%s", l.Addr())); nil == err {
		t.Fatal("GET / should have failed after server stopped")
	}
}

func TestServerGracefulStopKeepAlive(t *testing.T) {
	s := NewServer(
		"127.0.0.1:0",
		http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusNoContent)
		}),
	)
	l, err := net.Listen("tcp", s.Addr)
	if nil != err {
		t.Fatal(err)
	}
	go s.Serve(l)
	if _, err := http.Get(fmt.Sprintf("http://%s", l.Addr())); nil != err {
		t.Fatal(err)
	}
	then := time.Now()
	s.Close()
	now := time.Now()
	if then.Add(510 * time.Millisecond).Before(now) {
		t.Fatal("connection not closed quickly")
	}
	if _, err := http.Get(fmt.Sprintf("http://%s", l.Addr())); nil == err {
		t.Fatal("GET / should have failed after server stopped")
	}
}

func TestServerGracefulStopMulti(t *testing.T) {
	s := NewServer(
		"127.0.0.1:0",
		http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusNoContent)
		}),
	)
	l1, err := net.Listen("tcp", s.Addr)
	if nil != err {
		t.Fatal(err)
	}
	l2, err := net.Listen("tcp", s.Addr)
	if nil != err {
		t.Fatal(err)
	}
	go s.Serve(l1)
	go s.Serve(l2)
	if _, err := http.Get(fmt.Sprintf("http://%s", l1.Addr())); nil != err {
		t.Fatal(err)
	}
	if _, err := http.Get(fmt.Sprintf("http://%s", l2.Addr())); nil != err {
		t.Fatal(err)
	}
	then := time.Now()
	s.Close()
	now := time.Now()
	if then.Add(510 * time.Millisecond).Before(now) {
		t.Fatal("connection not closed quickly")
	}
	if _, err := http.Get(fmt.Sprintf("http://%s", l1.Addr())); nil == err {
		t.Fatal("GET / should have failed after server stopped")
	}
	if _, err := http.Get(fmt.Sprintf("http://%s", l2.Addr())); nil == err {
		t.Fatal("GET / should have failed after server stopped")
	}
}
