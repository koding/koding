package api

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
)

func TestCustomer(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				Convey("Then Group should have customer id", func() {
					group, err := modelhelper.GetGroup(groupName)
					So(err, ShouldBeNil)
					So(group, ShouldNotBeNil)

					So(group.Payment.Customer.ID, ShouldNotBeBlank)
					Convey("We should be able to get the customer", func() {
						getUrl := fmt.Sprintf("%s%s", endpoint, EndpointCustomerGet)
						updateUrl := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)

						res, err := rest.DoRequestWithAuth("GET", getUrl, nil, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						v := &stripe.Customer{}
						err = json.Unmarshal(res, v)
						So(err, ShouldBeNil)

						So(v.Deleted, ShouldEqual, false)
						So(v.Desc, ShouldContainSubstring, groupName)
						So(len(v.Meta), ShouldBeGreaterThanOrEqualTo, 2)
						So(v.Meta["groupName"], ShouldEqual, groupName)
						So(v.Meta["username"], ShouldEqual, username)

						withTestCreditCardToken(func(token string) {

							cp := &stripe.CustomerParams{
								Source: &stripe.SourceParams{
									Token: token,
								},
							}

							req, err := json.Marshal(cp)
							So(err, ShouldBeNil)
							So(req, ShouldNotBeNil)

							res, err := rest.DoRequestWithAuth("POST", updateUrl, req, sessionID)
							So(err, ShouldBeNil)
							So(res, ShouldNotBeNil)

							res, err = rest.DoRequestWithAuth("GET", getUrl, nil, sessionID)
							So(err, ShouldBeNil)
							So(res, ShouldNotBeNil)

							v = &stripe.Customer{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)

							So(v.DefaultSource, ShouldNotBeNil)
							So(v.DefaultSource.Deleted, ShouldBeFalse)
							So(v.DefaultSource.ID, ShouldNotBeEmpty)
						})
					})
				})
			})
		})
	})
}

func TestCouponApply(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestCoupon(func(couponID string) {
					updateUrl := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)

					cp := &stripe.CustomerParams{
						Coupon: couponID,
					}

					req, err := json.Marshal(cp)
					So(err, ShouldBeNil)
					So(req, ShouldNotBeNil)

					res, err := rest.DoRequestWithAuth("POST", updateUrl, req, sessionID)
					So(err, ShouldBeNil)
					So(res, ShouldNotBeNil)

					v := &stripe.Customer{}
					err = json.Unmarshal(res, v)
					So(err, ShouldBeNil)

					So(v.Discount, ShouldNotBeNil)
					So(v.Discount.Coupon.ID, ShouldEqual, couponID)
					So(v.Discount.Coupon.Valid, ShouldBeTrue)
					So(v.Discount.Coupon.Deleted, ShouldBeFalse)
				})
			})
		})
	})
}
