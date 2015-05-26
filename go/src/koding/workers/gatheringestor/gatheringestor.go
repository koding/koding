package main

import (
	"net/http"

	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type GatherIngestor struct {
	log logging.Logger
	dog *metrics.DogStatsD
}

func (g *GatherIngestor) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("OK"))
}
