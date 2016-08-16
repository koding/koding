package payment

import (
	"encoding/json"
	"fmt"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
)

func TestCreditCard(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				Convey("When a credit card added", func() {
					withTestCreditCardToken(func(token string) {
						updateUrl := fmt.Sprintf("%s/payment/customer/update", endpoint)
						getUrl := fmt.Sprintf("%s/payment/customer/get", endpoint)

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
						Convey("Customer should have the credit card", func() {
							c1 := &stripe.Customer{}
							err = json.Unmarshal(res, c1)
							So(err, ShouldBeNil)

							So(c1.DefaultSource, ShouldNotBeNil)
							So(c1.DefaultSource.Deleted, ShouldBeFalse)
							So(c1.DefaultSource.ID, ShouldNotBeEmpty)
							Convey("After updating the credit card", func() {
								withTestCreditCardToken(func(token string) {
									cp := &stripe.CustomerParams{
										Source: &stripe.SourceParams{
											Token: token,
										},
									}

									req, err := json.Marshal(cp)
									So(err, ShouldBeNil)
									So(req, ShouldNotBeNil)

									res, err = rest.DoRequestWithAuth("POST", updateUrl, req, sessionID)
									So(err, ShouldBeNil)
									So(res, ShouldNotBeNil)

									c2 := &stripe.Customer{}
									err = json.Unmarshal(res, c2)
									So(err, ShouldBeNil)
									Convey("Customer should have the new credit card", func() {
										So(c2.DefaultSource, ShouldNotBeNil)
										So(c2.DefaultSource.Deleted, ShouldBeFalse)
										So(c2.DefaultSource.ID, ShouldNotBeEmpty)

										// current and previous cc id should not be same
										So(c1.DefaultSource.ID, ShouldNotEqual, c2.DefaultSource.ID)

										Convey("After deleting the credit card", func() {
											ccdeleteUrl := fmt.Sprintf("%s/payment/creditcard/delete", endpoint)

											res, err = rest.DoRequestWithAuth("DELETE", ccdeleteUrl, nil, sessionID)
											So(err, ShouldBeNil)
											So(res, ShouldNotBeNil)

											c := &stripe.Card{}
											err = json.Unmarshal(res, c)
											So(err, ShouldBeNil)
											So(c.Deleted, ShouldBeTrue)

											res, err = rest.DoRequestWithAuth("GET", getUrl, nil, sessionID)
											So(err, ShouldBeNil)
											So(res, ShouldNotBeNil)

											Convey("Customer should not have the a credit card", func() {
												c3 := &stripe.Customer{}
												err = json.Unmarshal(res, c3)
												So(err, ShouldBeNil)
												So(c3.DefaultSource, ShouldBeNil)
												So(len(c3.Sources.Values), ShouldEqual, 0)
											})
										})
									})
								})
							})
						})
					})
				})
			})
		})
	})
}
