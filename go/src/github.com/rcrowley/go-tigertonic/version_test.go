package tigertonic

import (
	"net/http"
	"testing"
)

func TestVersion(t *testing.T) {
	w := &testResponseWriter{}
	Version("version").ServeHTTP(w, nil)
	if http.StatusOK != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
	if "version\n" != w.Body.String() {
		t.Fatal(w.Body.String())
	}
}

func TestVersionNotFound(t *testing.T) {
	w := &testResponseWriter{}
	Version("").ServeHTTP(w, nil)
	if http.StatusNotFound != w.StatusCode {
		t.Fatal(w.StatusCode)
	}
}
