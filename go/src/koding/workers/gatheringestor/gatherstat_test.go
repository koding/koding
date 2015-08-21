package main

import (
	"bytes"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	. "github.com/smartystreets/goconvey/convey"
)

func TestGatherStat(t *testing.T) {
	Convey("It should save stats", t, func() {
		dogclient, err := metrics.NewDogStatsD(WorkerName)
		So(err, ShouldBeNil)

		log := logging.NewLogger(WorkerName)

		mux := http.NewServeMux()
		mux.Handle("/", &GatherStat{dog: dogclient, log: log})

		server := httptest.NewServer(mux)
		defer server.Close()

		reqBuf := bytes.NewBuffer([]byte(`{"username":"indianajones"}`))

		res, err := http.Post(server.URL, "application/json", reqBuf)
		So(err, ShouldBeNil)

		defer res.Body.Close()

		So(res.StatusCode, ShouldEqual, 200)

		docs, err := modeltesthelper.GetGatherStatsForUser("indianajones")
		So(err, ShouldBeNil)

		So(len(docs), ShouldEqual, 1)
		So(docs[0].Username, ShouldEqual, "indianajones")

		Reset(func() {
			modeltesthelper.DeleteGatherStatsForUser("indianajones")
		})
	})
}
