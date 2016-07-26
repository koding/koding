package tigertonic

import (
	"io/ioutil"
	"net/http"
	"testing"
)

func TestNotFound(t *testing.T) {
	mux := NewTrieServeMux()
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	mux.ServeHTTP(w, r)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestMethodNotAllowed(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("POST", "/", func(w http.ResponseWriter, r *http.Request) {})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	mux.ServeHTTP(w, r)
	if http.StatusMethodNotAllowed != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestOPTIONS(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/foo", func(w http.ResponseWriter, r *http.Request) {})
	mux.HandleFunc("POST", "/bar", func(w http.ResponseWriter, r *http.Request) {})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("OPTIONS", "http://example.com/foo", nil)
	r.Header.Set(CORSRequestMethod, "GET")

	mux.ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "GET, HEAD, OPTIONS" != w.Header().Get("Allow") {
		t.Fatal(w.Header().Get("Allow"))
	}
	if "GET, HEAD, OPTIONS" != w.Header().Get(CORSAllowMethods) {
		t.Fatal(w.Header().Get("Allow"))
	}

	w = &testResponseWriter{}
	r, _ = http.NewRequest("OPTIONS", "http://example.com/bar", nil)
	mux.ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "OPTIONS, POST" != w.Header().Get("Allow") {
		t.Fatal(w.Header().Get("Allow"))
	}
}

func TestRoot(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	mux.ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestRecurse(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/foo/bar/baz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo/bar/baz", nil)
	mux.ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestParams(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/{foo}/{bar}", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		if "bar" != q.Get("foo") || "foo" != q.Get("bar") {
			t.Fatal(q.Get("foo"), q.Get("bar"))
		}
		if "bar" != q.Get("{foo}") || "foo" != q.Get("{bar}") {
			t.Fatal(q.Get("{foo}"), q.Get("{bar}"))
		}
		if "quux" != q.Get("baz") {
			t.Fatal(q.Get("quux"))
		}
		w.WriteHeader(http.StatusNoContent)
	})
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/bar/foo?baz=quux", nil)
	mux.ServeHTTP(w, r)
	if http.StatusNoContent != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestNamespace(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/bar", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(r.URL.Path))
	})
	nsMux := NewTrieServeMux()
	nsMux.HandleNamespace("", NotFoundHandler{}) // Test longest match wins.
	nsMux.HandleNamespace("/foo", mux)
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo/bar", nil)
	nsMux.ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "/bar" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestNamespaceParam(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/bar", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		if "bar" != q.Get("foo") {
			t.Fatal(q.Get("foo"))
		}
		if "bar" != q.Get("{foo}") {
			t.Fatal(q.Get("{foo}"))
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(r.URL.Path))
	})
	nsMux := NewTrieServeMux()
	nsMux.HandleNamespace("/{foo}", mux)
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/bar/bar", nil)
	nsMux.ServeHTTP(w, r)
	if http.StatusOK != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "/bar" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestHandler(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/foo/{bar}/baz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	r, _ := http.NewRequest("GET", "http://example.com/foo/bar/baz", nil)
	_, pattern := mux.Handler(r)
	if "/foo/{bar}/baz" != pattern {
		t.Fatal(pattern)
	}
}

func TestLiteralBeforeWildcard(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/literal", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	mux.HandleFunc("GET", "/{wildcard}", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	})
	r, _ := http.NewRequest("GET", "http://example.com/literal", nil)
	_, pattern := mux.Handler(r)
	if "/literal" != pattern {
		t.Fatal(pattern)
	}
}

func TestCollidingQueryParam(t *testing.T) {
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/{foo}/bar", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(r.URL.Query().Get("foo")))
	})
	r, _ := http.NewRequest("GET", "http://example.com/baz/bar?foo=quuz", nil)
	w := &testResponseWriter{}
	mux.ServeHTTP(w, r)
	contents, _ := ioutil.ReadAll(&w.Body)
	if string(contents) != "baz" {
		t.Fatal("Param passed in via query parameter overwrote URL param")
	}
}
