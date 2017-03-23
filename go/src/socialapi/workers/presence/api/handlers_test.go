package api

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/tests"
	"socialapi/workers/presence"
	"socialapi/workers/presence/client"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestPing(t *testing.T) {
	Convey("Given testing user & group", t, func() {
		withTestServer(t, func(endpoint string) {
			models.WithStubData(func(username, groupName, sessionID string) {
				Convey("We should be able to send the ping request to", func() {
					externalURL := endpoint + presence.EndpointPresencePing
					privateURL := endpoint + presence.EndpointPresencePingPrivate

					acc := &models.Account{}
					err := acc.ByNick(username)
					tests.ResultedWithNoErrorCheck(acc, err)

					Convey("external endpoint", func() {
						_, err := rest.DoRequestWithAuth("GET", externalURL, nil, sessionID)
						So(err, ShouldBeNil)

						pp := &presence.PrivatePing{
							GroupName: groupName,
							Username:  username,
						}
						req, err := json.Marshal(pp)
						tests.ResultedWithNoErrorCheck(req, err)
						Convey("internal endpoint without auth", func() {
							_, err := rest.DoRequestWithAuth("POST", privateURL, req, "")
							So(err, ShouldBeNil)
						})
					})
				})
			})
		})
	})
}

func TestPingWithClient(t *testing.T) {
	Convey("Given testing user & group", t, func() {
		withTestServer(t, func(endpoint string) {
			models.WithStubData(func(username, groupName, sessionID string) {
				Convey("We should be able to send the ping request", func() {
					Convey("with public client", func() {
						c := client.NewPublic(endpoint)
						err := c.Ping(sessionID, "groupName")
						So(err, ShouldBeNil)

						Convey("with internal client", func() {
							c := client.NewInternal(endpoint)
							err := c.Ping(username, groupName)
							So(err, ShouldBeNil)
						})
					})
				})
			})
		})
	})
}

//TODO(cihangir): below shamelessly copied from payment api tests with small
//modifications, unify them.

func withTestServer(t *testing.T, f func(url string)) {
	const workerName = "pingtest"

	r := runner.New(workerName)
	if err := r.Init(); err != nil {
		t.Fatal(err)
	}

	c := config.MustRead(r.Conf.Path)
	// init mongo connection
	modelhelper.Initialize(c.Mongo)
	defer modelhelper.Close()

	port := tests.GetFreePort()
	mc := mux.NewConfig(workerName, "localhost", port)
	mc.Debug = r.Conf.Debug
	m := mux.New(mc, r.Log, r.Metrics)

	AddHandlers(m)

	m.Listen()

	go r.Listen()

	f(fmt.Sprintf("http://localhost:%s", port))

	if err := r.Close(); err != nil {
		t.Fatalf("server close errored: %s", err.Error())
	}

	// shutdown server
	m.Close()
}
