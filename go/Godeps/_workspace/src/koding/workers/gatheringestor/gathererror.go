package main

import (
	"encoding/json"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type GatherError struct {
	log logging.Logger
	dog *metrics.DogStatsD
}

func (g *GatherError) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r != nil {
		defer r.Body.Close()
	}

	var req = models.GatherError{Id: bson.NewObjectId()}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		write404Err(g.log, err, w)
		return
	}

	if err := modelhelper.SaveGatherError(&req); err != nil {
		write500Err(g.log, err, w)
		return
	}

	w.WriteHeader(200)
}
