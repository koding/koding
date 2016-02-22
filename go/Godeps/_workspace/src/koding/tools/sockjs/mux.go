package sockjs

import (
	"net/http"
	"strings"
)

type Mux struct {
	Handlers map[string]http.Handler
}

func (mux *Mux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	for baseUrl, handler := range mux.Handlers {
		if strings.HasPrefix(strings.ToLower(r.URL.Path), baseUrl) {
			r.URL.Path = r.URL.Path[len(baseUrl):]
			handler.ServeHTTP(w, r)
			return
		}
	}
	http.NotFound(w, r)
}
