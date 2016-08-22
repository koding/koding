package api

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripe "github.com/stripe/stripe-go"
)

func TestCreateSubscription(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestPlan(func(planID string) {
					createURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCreate)
					deleteURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionDelete)
					getURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionGet)

					group, err := modelhelper.GetGroup(groupName)
					So(err, ShouldBeNil)
					So(group, ShouldNotBeNil)

					Convey("We should be able to create a subscription", func() {
						req, err := json.Marshal(&stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     planID,
						})
						So(err, ShouldBeNil)
						So(req, ShouldNotBeNil)

						res, err := rest.DoRequestWithAuth("POST", createURL, req, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						res, err = rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						v := &stripe.Sub{}
						err = json.Unmarshal(res, v)
						So(err, ShouldBeNil)
						So(v.Status, ShouldEqual, "active")
						Convey("We should be able to cancel the subscription", func() {
							res, err = rest.DoRequestWithAuth("DELETE", deleteURL, req, sessionID)
							So(err, ShouldBeNil)
							So(res, ShouldNotBeNil)

							res, err = rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
							So(err, ShouldBeNil)
							So(res, ShouldNotBeNil)

							v = &stripe.Sub{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)
							So(v.Status, ShouldEqual, "canceled")
						})
					})
				})
			})
		})
	})
}
