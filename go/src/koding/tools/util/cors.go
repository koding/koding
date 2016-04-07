package util

import (
	"net/http"
	"sort"
)

func header(values ...string) string {
	m := make(map[string]struct{}, len(values))
	for _, v := range values {
		m[v] = struct{}{}
	}

	delete(m, "")

	v := make([]string, 0, len(m))
	for k := range m {
		v = append(v, k)
	}

	sort.Strings(v)

	return (http.Header{"X-HEADER": v}).Get("X-HEADER")
}

func HandleCORS(w http.ResponseWriter, r *http.Request) (handled bool) {
	w.Header().Set("Access-Control-Allow-Origin", "*")

	if origin := r.Header.Get("Origin"); origin != "" && origin != "null" {
		w.Header().Set("Access-Control-Allow-Origin", origin)
	}

	if r.Method == "OPTIONS" {
		requested := w.Header().Get("Access-Control-Request-Method")

		if h := header(requested, "OPTIONS", "HEAD", "CONNECT"); h != "" {
			w.Header().Set("Access-Control-Allow-Methods", h)
		}

		if v := r.Header.Get("Access-Control-Request-Headers"); v != "" {
			w.Header().Set("Access-Control-Allow-Headers", v)
		}

		w.Header().Set("Access-Control-Allow-Credentials", "true")

		w.WriteHeader(204)

		return true
	}

	return false
}
