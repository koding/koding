package main

import (
	"encoding/json"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"

	"labix.org/v2/mgo/bson"

	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type GatherStat struct {
	log logging.Logger
	dog *metrics.DogStatsD
}

func (g *GatherStat) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req = &models.GatherStat{Id: bson.NewObjectId()}
	if err := json.NewDecoder(r.Body).Decode(req); err != nil {
		writeError(err, w)
		return
	}

	if err := modelhelper.SaveGatherStat(req); err != nil {
		writeError(err, w)
		return
	}

	name := fmt.Sprintf("gather:stats:%s", req.Name)
	tags := []string{"username:" + req.Username, "env" + req.Env}

	// name, value, tags, rate
	if err := g.dog.Gauge(name, req.Number, tags, 1.0); err != nil {
		writeError(err, w)
		return
	}

	w.WriteHeader(200)
}
