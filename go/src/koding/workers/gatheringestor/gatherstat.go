package main

import (
	"encoding/json"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type GatherStat struct {
	log logging.Logger
	dog *metrics.DogStatsD
}

func (g *GatherStat) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r != nil {
		defer r.Body.Close()
	}

	var req = &models.GatherStat{Id: bson.NewObjectId()}
	if err := json.NewDecoder(r.Body).Decode(req); err != nil {
		write404Err(g.log, err, w)
		return
	}

	if err := modelhelper.SaveGatherStat(req); err != nil {
		write500Err(g.log, err, w)
		return
	}

	for _, stat := range req.Stats {
		name := fmt.Sprintf("gather:stats:%s", stat.Name)
		tags := []string{"username:" + req.Username, "env" + req.Env}

		var value float64

		switch stat.Value.(type) {
		case int:
			value = float64(stat.Value.(int))
		case float64:
			value = stat.Value.(float64)
		default:
			continue
		}

		// name, value, tags, rate
		if err := g.dog.Gauge(name, value, tags, 1.0); err != nil {
			g.log.Error("Sending to datadog failed: %s", err)
			continue
		}
	}

	w.WriteHeader(200)
}
