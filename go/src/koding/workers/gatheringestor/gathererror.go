package main

import (
	"encoding/json"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"

	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type GatherError struct {
	log logging.Logger
	dog *metrics.DogStatsD
}

func (g *GatherError) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req models.GatherError
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(g.log, err, w)
		return
	}

	if err := modelhelper.SaveGatherError(&req); err != nil {
		writeError(g.log, err, w)
		return
	}

	w.WriteHeader(200)
}
