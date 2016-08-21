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
					createUrl := fmt.Sprintf("%s/payment/subscription/create", endpoint)
					deleteUrl := fmt.Sprintf("%s/payment/subscription/delete", endpoint)
					getUrl := fmt.Sprintf("%s/payment/subscription/get", endpoint)

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

						res, err := rest.DoRequestWithAuth("POST", createUrl, req, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						res, err = rest.DoRequestWithAuth("GET", getUrl, nil, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						v := &stripe.Sub{}
						err = json.Unmarshal(res, v)
						So(err, ShouldBeNil)
						So(v.Status, ShouldEqual, "active")
						Convey("We should be able to cancel the subscription", func() {
							res, err = rest.DoRequestWithAuth("DELETE", deleteUrl, req, sessionID)
							So(err, ShouldBeNil)
							So(res, ShouldNotBeNil)

							res, err = rest.DoRequestWithAuth("GET", getUrl, nil, sessionID)
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
