package api_test

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/metrics"
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

					countly, err := modelhelper.FetchCountlyInfo(groupName)
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

var td = [][]byte{
	[]byte(`config_show_timing:1.63938732|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:2.6393873|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:3.639387|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:8|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
}

func TestPublishEndpoint(t *testing.T) {
	Convey("Given testing user & group", t, func() {
		withTestServer(t, func(endpoint string) {
			models.WithStubData(func(username, groupName, sessionID string) {
				Convey("We should be able to create a countly app", func() {
					publishURL := endpoint + api.EndpointPublishKite
					gzm := &metrics.PublishRequest{
						Data: metrics.GzippedPayload(td),
					}
					data, err := json.Marshal(gzm)
					So(err, ShouldBeNil)

					res, err := rest.DoRequestWithAuth("POST", publishURL, data, sessionID)
					So(err, ShouldBeNil)
					So(res, ShouldNotBeNil)
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
