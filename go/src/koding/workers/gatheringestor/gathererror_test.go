package main

import (
	"bytes"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/koding/metrics"
	. "github.com/smartystreets/goconvey/convey"
)

func TestGatherError(t *testing.T) {
	Convey("It should save errors", t, func() {
		dogclient, err := metrics.NewDogStatsD(WorkerName)
		So(err, ShouldBeNil)

		mux := http.NewServeMux()
		mux.Handle("/", &GatherError{dog: dogclient})

		server := httptest.NewServer(mux)
		defer server.Close()

		reqBuf := bytes.NewBuffer([]byte(`{"error":"failed to run", "username":"indianajones"}`))

		res, err := http.Post(server.URL, "application/json", reqBuf)
		So(err, ShouldBeNil)

		defer res.Body.Close()

		So(res.StatusCode, ShouldEqual, 200)

		docs, err := modeltesthelper.GetGatherErrorsForUser("indianajones")
		So(err, ShouldBeNil)

		So(len(docs), ShouldEqual, 1)
		So(docs[0].Error, ShouldEqual, "failed to run")

		Reset(func() {
			modeltesthelper.DeleteGatherErrorsForUser("indianajones")
		})
	})
}
