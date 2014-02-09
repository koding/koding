package tigertonic

import (
	"net/http"
	"sync"
	"testing"
)

func TestContext(t *testing.T) {
	ch := make(chan bool)
	wg := &sync.WaitGroup{}
	mux := NewTrieServeMux()
	mux.HandleFunc("GET", "/1", func(w http.ResponseWriter, r *http.Request) {
		if 1 != len(contexts) {
			t.Error(contexts)
		}
		<-ch
		w.WriteHeader(http.StatusNoContent)
	})
	mux.HandleFunc("GET", "/2", func(w http.ResponseWriter, r *http.Request) {
		if 2 != len(contexts) {
			t.Error(contexts)
		}
		ch <- true
		w.WriteHeader(http.StatusNoContent)
	})
	handler := WithContext(mux, testContext{})
	wg.Add(2)
	go func() {
		w := &testResponseWriter{}
		r, _ := http.NewRequest("GET", "http://example.com/1", nil)
		handler.ServeHTTP(w, r)
		wg.Done()
	}()
	go func() {
		w := &testResponseWriter{}
		r, _ := http.NewRequest("GET", "http://example.com/2", nil)
		handler.ServeHTTP(w, r)
		wg.Done()
	}()
	wg.Wait()
}

type testContext struct {
	Foo string
	Bar int
}
