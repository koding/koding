package main

import (
	"encoding/json"
	"fmt"
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
		writeError(err, w)
		return
	}

	if err := modelhelper.SaveGatherError(&req); err != nil {
		writeError(err, w)
		return
	}

	name := fmt.Sprintf("gather:errors:%s", req.Name)
	tags := []string{"username:" + req.Username, "env" + req.Env}

	// name, value, tags, rate
	if err := g.dog.Gauge(name, 1, tags, 1.0); err != nil {
		writeError(err, w)
		return
	}

	w.WriteHeader(200)
}
