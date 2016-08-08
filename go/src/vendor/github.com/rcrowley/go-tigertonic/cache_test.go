package tigertonic

import (
	"net/http"
	"testing"
	"time"
)

func TestCacheControl(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", nil)
	cached := Cached(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}), CacheOptions{MaxAge: time.Hour * 24 * 13, NoTransform: true})
	cached.ServeHTTP(w, r)

	if "no-transform, max-age=1123200" != w.Header().Get("Cache-Control") {
		t.Fatalf("Cache-Control headers were %s, expected 'no-transform, max-age=1123200'", w.Header().Get("Cache-Control"))
	}
}

// If the wrapped handler sets the Cache-Control header, we should not set it.
func TestCacheControlHandlerSetControl(t *testing.T) {
	w := &testResponseWriter{}
	r, _ := http.NewRequest("POST", "http://example.com/foo", nil)
	testFunc := func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "testing")
	}
	cached := Cached(http.HandlerFunc(testFunc), CacheOptions{MaxAge: time.Hour * 24 * 13, NoTransform: true})
	cached.ServeHTTP(w, r)

	if "testing" != w.Header().Get("Cache-Control") {
		t.Fatalf("Cache-Control headers were %s, expected 'testing'", w.Header().Get("Cache-Control"))
	}
}

var cacheOptions = []struct {
	o CacheOptions
	h string
}{
	{CacheOptions{Immutable: true, NoTransform: true}, "no-transform, max-age=31536000"},
	{CacheOptions{IsPrivate: true, NoTransform: true}, "private, no-transform"},
	{CacheOptions{MaxAge: time.Hour * 24 * 13, NoTransform: true}, "no-transform, max-age=1123200"},
	{CacheOptions{NoCache: true, NoTransform: true}, "no-cache, no-transform"},
	{CacheOptions{NoStore: true, NoTransform: true}, "no-store, no-transform"},
	{CacheOptions{NoTransform: false}, ""},
	{CacheOptions{MustRevalidate: true, NoTransform: true}, "no-transform, must-revalidate"},
	{CacheOptions{ProxyRevalidate: true, NoTransform: true}, "no-transform, proxy-revalidate"},
	{CacheOptions{SharedMaxAge: time.Hour * 13, NoTransform: true}, "no-transform, s-maxage=46800"},
}

func TestCacheOptions(t *testing.T) {
	for _, v := range cacheOptions {
		if o := v.o.String(); v.h != o {
			t.Fatalf("%#v got '%s', expected '%s'", v.o, o, v.h)
		}
	}
}
