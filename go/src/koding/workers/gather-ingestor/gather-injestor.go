package main

import (
	"net/http"

	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type GatherInjestor struct {
	log logging.Logger
	dog *metrics.DogStatsD
}

func (g *GatherInjestor) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("OK"))
}
