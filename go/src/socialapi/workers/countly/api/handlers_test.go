package api_test

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/tests"
	"socialapi/workers/countly/api"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateApp(t *testing.T) {
	Convey("Given testing user & group", t, func() {
		withTestServer(t, func(endpoint string) {
			models.WithStubData(func(username, groupName, sessionID string) {
				Convey("We should be able to create a countly app", func() {
					initURL := endpoint + api.EndpointInit

					res, err := rest.DoRequestWithAuth("GET", initURL, nil, sessionID)
					So(err, ShouldBeNil)
					So(res, ShouldNotBeNil)

					var keys map[string]string
					So(json.Unmarshal(res, &keys), ShouldBeNil)
					So(len(keys), ShouldEqual, 2)

					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					// check if we stored keys properly.
					So(group.Countly.APPKey, ShouldEqual, keys["appKey"])
					So(group.Countly.APIKey, ShouldEqual, keys["apiKey"])

					Convey("endpoint should be idempotent", func() {
						res, err := rest.DoRequestWithAuth("GET", initURL, nil, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						var keys2 map[string]string
						So(json.Unmarshal(res, &keys2), ShouldBeNil)
						So(len(keys2), ShouldEqual, 2)

						So(keys["appKey"], ShouldEqual, keys2["appKey"])
						So(keys["apiKey"], ShouldEqual, keys2["apiKey"])
					})
				})
			})
		})
	})
}

//TODO(cihangir): below shamelessly copied from payment api tests with small
//modifications, unify them. https://github.com/koding/koding/issues/10771

func withTestServer(t *testing.T, f func(url string)) {
	tests.WithRunner(t, func(r *runner.Runner) {
		port := tests.GetFreePort()
		mc := mux.NewConfig(r.Name, "localhost", port)
		mc.Debug = r.Conf.Debug
		m := mux.New(mc, r.Log, r.Metrics)

		api.AddHandlers(m, config.MustGet())

		m.Listen()

		go r.Listen()

		f("http://localhost:" + port)

		if err := r.Close(); err != nil {
			t.Fatalf("server close errored: %s", err.Error())
		}

		// shutdown server
		m.Close()
	})
}
