package api

import (
	"encoding/json"
	"fmt"
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
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						So(subscriptionID, ShouldNotBeEmpty)
						Convey("We should be able to get the subscription", func() {
							getURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionGet)
							res, err := rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
							So(err, ShouldBeNil)
							So(res, ShouldNotBeNil)

							v := &stripe.Sub{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)
							So(v.Status, ShouldEqual, "active")
						})
					})
				})
			})
		})
	})
}
