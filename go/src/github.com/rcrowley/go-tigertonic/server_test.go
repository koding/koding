package tigertonic

import (
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
		"127.0.0.1:8888",
		http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			time.Sleep(2 * time.Millisecond)
			w.WriteHeader(http.StatusNoContent)
			chT <- time.Now()
		}),
	)
	go s.ListenAndServe()
	chR := make(chan *http.Response, 1)
	go func() {
		rs, err := http.Get("http://127.0.0.1:8888/")
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
}
