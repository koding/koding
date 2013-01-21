package sockjs

import (
	"net/http"
	"strings"
)

type Mux struct {
	Services map[string]*Service
}

func (mux *Mux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	for baseUrl, service := range mux.Services {
		if strings.HasPrefix(r.URL.Path, baseUrl) {
			r.URL.Path = r.URL.Path[len(baseUrl):]
			service.ServeHTTP(w, r)
			return
		}
	}
	http.NotFound(w, r)
}
