package api_test

import (
	"encoding/json"
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

// This test is not run by the test runners because we dont have countly in our
// testing env yet.
// TODO(cihangir): add countly to testing env.

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
					So(len(keys), ShouldEqual, 3)

					countly, err := api.FetchCountlyInfo(groupName)
					tests.ResultedWithNoErrorCheck(countly, err)

					// check if we stored keys properly.
					So(countly.AppKey, ShouldEqual, keys["appKey"])
					So(countly.APIKey, ShouldEqual, keys["apiKey"])

					Convey("endpoint should be idempotent", func() {
						res, err := rest.DoRequestWithAuth("GET", initURL, nil, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						var keys2 map[string]string
						So(json.Unmarshal(res, &keys2), ShouldBeNil)
						So(len(keys2), ShouldEqual, 3)

						So(keys["appKey"], ShouldEqual, keys2["appKey"])
						So(keys["apiKey"], ShouldEqual, keys2["apiKey"])
					})
				})
			})
		})
	})
}

//TODO(cihangir): Unify them. https://github.com/koding/koding/issues/10771

func withTestServer(t *testing.T, f func(url string)) {
	tests.WithRunner(t, func(r *runner.Runner) {
		port := tests.GetFreePort()
		mc := mux.NewConfig(r.Name, "localhost", port)
		mc.Debug = r.Conf.Debug
		m := mux.New(mc, r.Log, r.Metrics)

		api.AddHandlers(m, config.MustGet())

		m.Listen()
		defer m.Close()

		go r.Listen()

		f("http://localhost:" + port)

		if err := r.Close(); err != nil {
			t.Fatalf("server close errored: %s", err.Error())
		}
	})
}
