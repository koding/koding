package tigertonic

import (
	"errors"
	"net/http"
	"testing"
)

func TestFirst1(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	First(NotFoundHandler{}).ServeHTTP(w, r)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestFirst2(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	First(noopHandler{}, NotFoundHandler{}).ServeHTTP(w, r)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestFirst3(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	First(noopHandler{}, noopHandler{}, NotFoundHandler{}).ServeHTTP(w, r)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestFirst4(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	First(NotFoundHandler{}, &fatalHandler{t}).ServeHTTP(w, r)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

func TestIfFalse(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	If(func(r *http.Request) (http.Header, error) {
		return http.Header{
			"WWW-Authenticate": []string{"Basic realm=\"Tiger Tonic\""},
		}, Unauthorized{errors.New("Unauthorized")}
	}, NotFoundHandler{}).ServeHTTP(w, r)
	if http.StatusUnauthorized != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if wwwAuthenticate := w.Header().Get("WWW-Authenticate"); "Basic realm=\"Tiger Tonic\"" != wwwAuthenticate {
		t.Fatal(w.Header())
	}
}

func TestIfTrue(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/", nil)
	If(func(r *http.Request) (http.Header, error) {
		return nil, nil
	}, NotFoundHandler{}).ServeHTTP(w, r)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}

type fatalHandler struct {
	t *testing.T
}

func (fh *fatalHandler) ServeHTTP(http.ResponseWriter, *http.Request) {
	fh.t.Fatal("fatalHandler")
}

type noopHandler struct{}

func (noopHandler) ServeHTTP(http.ResponseWriter, *http.Request) {}
