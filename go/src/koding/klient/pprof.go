// +build pprof

package main

import (
	"net/http"
	_ "net/http/pprof"

	"github.com/koding/logging"
)

func init() {
	l := logging.NewLogger("init")

	go func() {
		l.Info("Starting debug server on localhost:8080")
		l.Info("%s", http.ListenAndServe("localhost:8080", nil))
	}()
}
