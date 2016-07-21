package tigertonic

import (
	"fmt"
	"net/http"
)

// Version is an http.Handler that responds to every request with itself in
// plain text.  The version string may be anything you like and may be set
// at compile-time by adding
//
//     -ldflags "-X main.Version VERSION"
//
// to your build command.
type Version string

// ServeHTTP responds 200 with the version string or 404 if the version string
// is empty.
func (v Version) ServeHTTP(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	if "" == v {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, v)
}
