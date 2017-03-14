package api

import (
	"encoding/json"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"socialapi/workers/presence"
	"socialapi/workers/presence/client"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestPing(t *testing.T) {
	Convey("Given testing user & group", t, func() {
		tests.WithTestServer(t, AddHandlers, func(endpoint string) {
			tests.WithStubData(endpoint, func(username, groupName, sessionID string) {
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
		tests.WithTestServer(t, AddHandlers, func(endpoint string) {
			tests.WithStubData(endpoint, func(username, groupName, sessionID string) {
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
