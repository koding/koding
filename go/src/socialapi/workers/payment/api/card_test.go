package api

import (
	"encoding/json"
	"testing"

	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
)

func TestCreditCardDelete(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				Convey("When a credit card added", func() {
					withTestCreditCardToken(func(token string) {
						updateURL := endpoint + EndpointCustomerUpdate
						getURL := endpoint + EndpointCustomerGet

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
											ccdeleteURL := endpoint + EndpointCreditCardDelete

											_, err = rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, sessionID)
											tests.ResultedWithNoErrorCheck(res, err)

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

func TestCreditCardDeleteNonAdmin(t *testing.T) {
	Convey("When a non admin user request comes", t, func() {
		withTestServer(t, func(endpoint string) {
			acc, _, groupName := models.CreateRandomGroupDataWithChecks()

			ses, err := modelhelper.CreateSessionForAccount(acc.Nick, groupName)
			tests.ResultedWithNoErrorCheck(ses, err)

			Convey("Endpoint should return error", func() {
				ccdeleteURL := endpoint + EndpointCreditCardDelete
				_, err := rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, ses.ClientId)
				So(err, ShouldNotBeNil)
			})
		})
	})
}

func TestCreditCardDeleteLoggedOut(t *testing.T) {
	Convey("When a non registered request comes", t, func() {
		withTestServer(t, func(endpoint string) {
			Convey("Endpoint should return error", func() {
				ccdeleteURL := endpoint + EndpointCreditCardDelete
				_, err := rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, "")
				So(err, ShouldNotBeNil)
			})
		})
	})
}

func TestCreditCardDeleteNotSubscribingMember(t *testing.T) {
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
					ccdeleteURL := endpoint + EndpointCreditCardDelete
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

func TestCreditCardInfo(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				Convey("When a credit card added", func() {
					c1 := addCreditCardToUserWithChecks(endpoint, sessionID)

					Convey("Group should have the credit card", func() {
						_, err := rest.DoRequestWithAuth("GET", endpoint+EndpointCreditCardHas, nil, sessionID)
						So(err, ShouldBeNil)

						Convey("After updating the credit card", func() {
							c2 := addCreditCardToUserWithChecks(endpoint, sessionID)

							Convey("Group should still have a card", func() {
								_, err := rest.DoRequestWithAuth("GET", endpoint+EndpointCreditCardHas, nil, sessionID)
								So(err, ShouldBeNil)

								// current and previous cc id should not be same
								So(c1.DefaultSource.ID, ShouldNotEqual, c2.DefaultSource.ID)

								Convey("After deleting the credit card", func() {
									ccdeleteURL := endpoint + EndpointCreditCardDelete

									res, err := rest.DoRequestWithAuth("DELETE", ccdeleteURL, nil, sessionID)
									tests.ResultedWithNoErrorCheck(res, err)

									Convey("Customer should not have the a credit card", func() {
										_, err := rest.DoRequestWithAuth("GET", endpoint+EndpointCreditCardHas, nil, sessionID)
										So(err, ShouldNotBeNil)
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

func TestCreditCardInfoLoggedOut(t *testing.T) {
	Convey("When a non registered request comes", t, func() {
		withTestServer(t, func(endpoint string) {
			Convey("Endpoint should return error", func() {
				_, err := rest.DoRequestWithAuth("GET", endpoint+EndpointCreditCardHas, nil, "")
				So(err, ShouldNotBeNil)
			})
		})
	})
}

func TestCreditCardInfoNotSubscribingMember(t *testing.T) {
	Convey("When a non subscribed user request to get CC", t, func() {
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
					_, err := rest.DoRequestWithAuth("GET", endpoint+EndpointCreditCardHas, nil, sessionID)
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

func TestCreditCardAuthNoSession(t *testing.T) {
	Convey("When a non subscribed user request for Auth", t, func() {
		withTestServer(t, func(endpoint string) {
			withTestCreditCardToken(func(token string) {
				cp := &stripe.ChargeParams{
					Source: &stripe.SourceParams{
						Token: token,
					},
					Email: "testcreditcardauth@kd.io",
				}

				req, err := json.Marshal(cp)
				tests.ResultedWithNoErrorCheck(req, err)

				res, err := rest.DoRequestWithAuth("POST", endpoint+EndpointCreditCardAuth, req, "")
				So(err, ShouldNotBeNil)
				So(res, ShouldBeNil)
				So(err.Error(), ShouldContainSubstring, "does not have session id")
			})
		})
	})
}
func TestCreditCardAuthEmptyEmail(t *testing.T) {
	Convey("When a non subscribed user request for Auth", t, func() {
		withTestServer(t, func(endpoint string) {
			withTestCreditCardToken(func(token string) {
				testUsername := "guest-testcreditcardauth"
				testGroupName := "guests"

				ses, err := modelhelper.CreateSessionForAccount(testUsername, testGroupName)
				tests.ResultedWithNoErrorCheck(ses, err)

				cp := &stripe.ChargeParams{
					Source: &stripe.SourceParams{
						Token: token,
					},
				}

				req, err := json.Marshal(cp)
				tests.ResultedWithNoErrorCheck(req, err)

				res, err := rest.DoRequestWithAuth("POST", endpoint+EndpointCreditCardAuth, req, ses.ClientId)
				So(err, ShouldNotBeNil)
				So(res, ShouldBeNil)
				So(err.Error(), ShouldContainSubstring, "email is not set")
			})
		})
	})
}

func TestCreditCardAuthValid(t *testing.T) {
	Convey("When a non subscribed user request for Auth", t, func() {
		withTestServer(t, func(endpoint string) {
			withTestCreditCardToken(func(token string) {
				testUsername := "guest-testcreditcardauth"
				testGroupName := "guests"

				ses, err := modelhelper.CreateSessionForAccount(testUsername, testGroupName)
				tests.ResultedWithNoErrorCheck(ses, err)

				cp := &stripe.ChargeParams{
					Source: &stripe.SourceParams{
						Token: token,
					},
					Email: "testcreditcardauth@kd.io",
				}

				req, err := json.Marshal(cp)
				tests.ResultedWithNoErrorCheck(req, err)

				_, err = rest.DoRequestWithAuth("POST", endpoint+EndpointCreditCardAuth, req, ses.ClientId)
				So(err, ShouldBeNil)
			})
		})
	})
}

func TestCreditCardAuthRetryFail(t *testing.T) {
	Convey("When a non subscribed user request for Auth", t, func() {
		withTestServer(t, func(endpoint string) {
			withTestCreditCardToken(func(token string) {
				testUsername := "guest-testcreditcardauth"
				testGroupName := "guests"

				ses, err := modelhelper.CreateSessionForAccount(testUsername, testGroupName)
				tests.ResultedWithNoErrorCheck(ses, err)

				cp := &stripe.ChargeParams{
					Source: &stripe.SourceParams{
						Token: token,
					},
					Email: "testcreditcardauth@kd.io",
				}

				req, err := json.Marshal(cp)
				tests.ResultedWithNoErrorCheck(req, err)

				_, err = rest.DoRequestWithAuth("POST", endpoint+EndpointCreditCardAuth, req, ses.ClientId)
				So(err, ShouldBeNil)

				res, err := rest.DoRequestWithAuth("POST", endpoint+EndpointCreditCardAuth, req, ses.ClientId)
				So(err, ShouldNotBeNil)
				So(res, ShouldBeNil)
			})
		})
	})
}
