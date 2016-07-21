package tigertonic

import (
	"io/ioutil"
	"net/http"
	"net/url"
	"testing"
)

func TestPostProcessed(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("GET", "http://example.com/foo", nil)
	called := false
	PostProcessed(Marshaled(func(*url.URL, http.Header) (int, http.Header, *testResponse, error) {
		return http.StatusOK, http.Header{"X-Foo": []string{"bar"}}, &testResponse{"bar"}, nil
	}), func(_ *http.Request, r *http.Response) {
		called = true
		if http.StatusOK != r.StatusCode {
			t.Fatal(r.StatusCode)
		}
		if "bar" != r.Header.Get("X-Foo") {
			t.Fatal(r.Header)
		}
		body, _ := ioutil.ReadAll(r.Body)
		if "{\"foo\":\"bar\"}\n" != string(body) {
			t.Fatal(w.Body.String())
		}
	}).ServeHTTP(w, r)
	if !called {
		t.Fatal(called)
	}
}
