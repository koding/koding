package api

import (
	"encoding/json"
	"fmt"
	"testing"

	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
)

func TestCreditCard(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				Convey("When a credit card added", func() {
					withTestCreditCardToken(func(token string) {
						updateURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)
						getURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerGet)

						cp := &stripe.CustomerParams{
							Source: &stripe.SourceParams{
								Token: token,
							},
						}

						req, err := json.Marshal(cp)
						tests.ResultedWithNoErrorCheck(req, err)

						res, err := rest.DoRequestWithAuth("POST", updateURL, req, sessionID)
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
									tests.ResultedWithNoErrorCheck(req, err)

									res, err = rest.DoRequestWithAuth("POST", updateURL, req, sessionID)
									tests.ResultedWithNoErrorCheck(res, err)

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
											ccdeleteURL := fmt.Sprintf("%s%s", endpoint, EndpointCreditCardDelete)

											res, err = rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, sessionID)
											tests.ResultedWithNoErrorCheck(res, err)

											c := &stripe.Card{}
											err = json.Unmarshal(res, c)
											So(err, ShouldBeNil)
											So(c.Deleted, ShouldBeTrue)

											res, err = rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
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

func TestCreditCardNonAdmin(t *testing.T) {
	Convey("When a non admin user request comes", t, func() {
		withTestServer(t, func(endpoint string) {
			acc, _, groupName := models.CreateRandomGroupDataWithChecks()

			ses, err := models.FetchOrCreateSession(acc.Nick, groupName)
			tests.ResultedWithNoErrorCheck(ses, err)

			Convey("Endpoint should return error", func() {
				ccdeleteURL := fmt.Sprintf("%s%s", endpoint, EndpointCreditCardDelete)
				_, err := rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, ses.ClientId)
				So(err, ShouldNotBeNil)
			})
		})
	})
}

func TestCreditCardLoggedOut(t *testing.T) {
	Convey("When a non registered request comes", t, func() {
		withTestServer(t, func(endpoint string) {
			Convey("Endpoint should return error", func() {
				ccdeleteURL := fmt.Sprintf("%s%s", endpoint, EndpointCreditCardDelete)
				_, err := rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, "")
				So(err, ShouldNotBeNil)
			})
		})
	})
}

func TestCreditCardNotSubscribingMember(t *testing.T) {
	Convey("When a non subscribed user request to delete CC", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				err = modelhelper.UpdateGroupPartial(
					modelhelper.Selector{"_id": group.Id},
					modelhelper.Selector{
						"$unset": modelhelper.Selector{"payment.customer.id": ""},
					},
				)
				So(err, ShouldBeNil)

				Convey("Endpoint should return error", func() {
					ccdeleteURL := fmt.Sprintf("%s%s", endpoint, EndpointCreditCardDelete)
					_, err = rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, sessionID)
					So(err, ShouldNotBeNil)

					// set the customer id back becase test data callback requires it.
					err = modelhelper.UpdateGroupPartial(
						modelhelper.Selector{"_id": group.Id},
						modelhelper.Selector{
							"$set": modelhelper.Selector{"payment.customer.id": group.Payment.Customer.ID},
						},
					)
					So(err, ShouldBeNil)

				})
			})
		})
	})
}
