package api

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"socialapi/workers/payment"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
	"github.com/stripe/stripe-go/invoice"
)

func TestCustomer(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				Convey("Then Group should have customer id", func() {
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					So(group.Payment.Customer.ID, ShouldNotBeBlank)
					Convey("We should be able to get the customer", func() {
						getURL := endpoint + EndpointCustomerGet

						res, err := rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
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

						Convey("After adding credit card to the user", func() {
							addCreditCardToUserWithChecks(endpoint, sessionID)

							res, err = rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
							So(err, ShouldBeNil)
							So(res, ShouldNotBeNil)

							Convey("Customer should have CC assigned", func() {
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
	})
}

func TestCouponApply(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestCoupon(func(couponID string) {
					Convey("After adding coupon to the user", func() {

						updateURL := endpoint + EndpointCustomerUpdate

						cp := &stripe.CustomerParams{
							Coupon: couponID,
						}

						req, err := json.Marshal(cp)
						So(err, ShouldBeNil)
						So(req, ShouldNotBeNil)

						res, err := rest.DoRequestWithAuth("POST", updateURL, req, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						v := &stripe.Customer{}
						err = json.Unmarshal(res, v)
						So(err, ShouldBeNil)

						Convey("Customer should have coupon assigned", func() {
							So(v.Discount, ShouldNotBeNil)
							So(v.Discount.Coupon.ID, ShouldEqual, couponID)
							So(v.Discount.Coupon.Valid, ShouldBeTrue)
							So(v.Discount.Coupon.Deleted, ShouldBeFalse)
						})
					})
				})
			})
		})
	})
}

// TestBalanceApply does not test anything on our end. And i am not trying to be
// clever with testing stripe. This test is here only for making sure about the
// logic of Amount, Subtotal And the Total. This is the third time i am
// forgetting the logic and wanted to document it here with code.
func TestBalanceApply(t *testing.T) {
	Convey("Given a user who subscribed to a paid plan", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withNonFreeTestPlan(func(planID string) {
					addCreditCardToUserWithChecks(endpoint, sessionID)
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						withTestCoupon(func(couponID string) {
							Convey("After adding balance to the user", func() {
								group, err := modelhelper.GetGroup(groupName)
								tests.ResultedWithNoErrorCheck(group, err)
								var subtotal int64 = 12345
								// A negative amount represents a credit that
								// decreases the amount due on an invoice; a
								// positive amount increases the amount due on
								// an invoice.
								var balance int64 = -150
								var coupon int64 = 100

								expectedAmount := subtotal - coupon - (-balance) // negate the balance
								cp := &stripe.CustomerParams{
									Balance: balance,
									Coupon:  couponID,
								}

								c, err := customer.Update(group.Payment.Customer.ID, cp)
								tests.ResultedWithNoErrorCheck(c, err)

								Convey("Customer should have discount", func() {
									So(c, ShouldNotBeNil)
									So(c.Balance, ShouldEqual, balance)

									Convey("Invoice should the discount", func() {
										i, err := invoice.GetNext(&stripe.InvoiceParams{Customer: c.ID})
										tests.ResultedWithNoErrorCheck(i, err)
										So(i.Subtotal, ShouldEqual, subtotal)
										So(i.Subtotal, ShouldBeGreaterThan, i.Total)
										So(i.Subtotal, ShouldEqual, i.Total+coupon) // dont forget to negate

										So(i.Total, ShouldEqual, subtotal-coupon)
										So(i.Total, ShouldBeGreaterThan, i.Amount)
										So(i.Total, ShouldEqual, i.Amount+(-balance))

										So(i.Amount, ShouldEqual, i.Total-(-balance))
										So(i.Amount, ShouldEqual, expectedAmount)
										// Subtotal = amount + coupon + balance
										// Total    = amount + coupon
										// Amount   = the final price that customer will pay.

										// Subtotal:     12345,
										// Total:        12245,
										// Amount:       12145,

										// Expected: '12245'
										// Actual:   '12445'
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

func TestInfoPlan(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestPlan(func(planID string) {
					addCreditCardToUserWithChecks(endpoint, sessionID)
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						Convey("We should be able to get info", func() {
							infoURL := endpoint + EndpointInfo
							res, err := rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							v := &payment.Usage{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)

							// we use "in" here because presence request is not synchronous and might create issues
							So(v.ExpectedPlan.ID, ShouldBeIn, []string{payment.Free, payment.Solo})
						})
					})
				})
			})
		})
	})
}

func TestCreateCustomCustomer(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withTestCreditCardToken(func(token string) {
				Convey("We should be able to create a custom user", func() {
					cp := &stripe.CustomerParams{
						Token: token,
						Email: "test@koding.com",
						Params: stripe.Params{
							Meta: map[string]string{
								"phone": "5555555",
							},
						},
					}

					req, err := json.Marshal(cp)
					So(err, ShouldBeNil)
					So(req, ShouldNotBeNil)

					customURL := endpoint + EndpointCustomCustomerCreate
					res, err := rest.DoRequest("POST", customURL, req)
					tests.ResultedWithNoErrorCheck(res, err)

					v := &stripe.Customer{}
					err = json.Unmarshal(res, v)
					So(err, ShouldBeNil)
					So(v, ShouldNotBeNil)
					So(len(v.Meta), ShouldBeGreaterThan, 0)
				})
			})
		})
	})
}
