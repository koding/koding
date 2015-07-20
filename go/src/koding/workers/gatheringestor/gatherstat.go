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
		writeError(g.log, err, w)
		return
	}

	if err := modelhelper.SaveGatherStat(req); err != nil {
		writeError(g.log, err, w)
		return
	}

	for _, stat := range req.Stats {
		name := fmt.Sprintf("gather:stats:%s", stat.Name)
		tags := []string{"username:" + req.Username, "env" + req.Env}

		// name, value, tags, rate
		if err := g.dog.Gauge(name, stat.Number, tags, 1.0); err != nil {
			continue
		}
	}

	w.WriteHeader(200)
}
