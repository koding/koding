package tigertonic

import (
	"net/http"
	"net/url"
	"testing"
)

func TestTeeHeaderResponseWriter(t *testing.T) {
	w0 := &testResponseWriter{}
	w := NewTeeHeaderResponseWriter(w0)
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	Marshaled(func(*url.URL, http.Header) (int, http.Header, *testResponse, error) {
		return http.StatusOK, http.Header{"X-Foo": []string{"bar"}}, &testResponse{"bar"}, nil
	}).ServeHTTP(w, r)
	if w0.StatusCode != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if w0.Header().Get("X-Foo") != w.Header().Get("X-Foo") {
		t.Fatal(w.Header())
	}
}

func TestTeeResponseWriter(t *testing.T) {
	w0 := &testResponseWriter{}
	w := NewTeeResponseWriter(w0)
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	Marshaled(func(*url.URL, http.Header) (int, http.Header, *testResponse, error) {
		return http.StatusOK, http.Header{"X-Foo": []string{"bar"}}, &testResponse{"bar"}, nil
	}).ServeHTTP(w, r)
	if w0.StatusCode != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if w0.Header().Get("X-Foo") != w.Header().Get("X-Foo") {
		t.Fatal(w.Header())
	}
	if w0.Body.String() != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}
