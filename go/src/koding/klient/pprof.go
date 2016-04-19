// +build pprof

package main

import (
	"net/http"
	_ "net/http/pprof"

	"github.com/koding/logging"
)

func init() {
	go func() {
		l := logging.NewLogger("debug")
		l.Info("Starting debug server on localhost:8888")

		l.Info("%s", http.ListenAndServe("localhost:8888", nil))
	}()
}
