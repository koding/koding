package tigertonic

import (
	"net/http"
	"testing"
)

func TestHostnameFound(t *testing.T) {
	mux := NewHostServeMux()
	mux.HandleFunc("example.com", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	mux.ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestHostnameFoundInURL(t *testing.T) {
	mux := NewHostServeMux()
	mux.HandleFunc("example.com", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	r.Host = ""
	mux.ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestHostnameNotFound(t *testing.T) {
	mux := NewHostServeMux()
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	mux.ServeHTTP(w, r)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestHostnameWithPortFound(t *testing.T) {
	mux := NewHostServeMux()
	mux.HandleFunc("example.com", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com:80/", nil)
	mux.ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestHostnameWithPortFoundInURL(t *testing.T) {
	mux := NewHostServeMux()
	mux.HandleFunc("example.com", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com:80/", nil)
	r.Host = ""
	mux.ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}
