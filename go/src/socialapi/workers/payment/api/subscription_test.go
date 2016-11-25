package api

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
	stripe "github.com/stripe/stripe-go"
	currency "github.com/stripe/stripe-go/currency"
	stripeplan "github.com/stripe/stripe-go/plan"
	stripesub "github.com/stripe/stripe-go/sub"
)

func TestCreateSubscription(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestPlan(func(planID string) {
					withTestCreditCardToken(func(token string) {
						updateURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)
						cp := &stripe.CustomerParams{
							Source: &stripe.SourceParams{
								Token: token,
							},
						}
						req, err := json.Marshal(cp)
						tests.ResultedWithNoErrorCheck(req, err)
						res, err := rest.DoRequestWithAuth("POST", updateURL, req, sessionID)
						tests.ResultedWithNoErrorCheck(res, err)

						withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
							So(subscriptionID, ShouldNotBeEmpty)
							getURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionGet)
							res, err := rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

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

func TestCreateSubscriptionWithPlan(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withNonFreeTestPlan(func(planID string) {
					withTestCreditCardToken(func(token string) {
						updateURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)

						cp := &stripe.CustomerParams{
							Source: &stripe.SourceParams{
								Token: token,
							},
						}

						req, err := json.Marshal(cp)
						tests.ResultedWithNoErrorCheck(req, err)

						res, err := rest.DoRequestWithAuth("POST", updateURL, req, sessionID)
						tests.ResultedWithNoErrorCheck(res, err)

						withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
							So(subscriptionID, ShouldNotBeEmpty)
							Convey("We should be able to get the subscription", func() {
								getURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionGet)
								res, err := rest.DoRequestWithAuth("GET", getURL, nil, sessionID)
								tests.ResultedWithNoErrorCheck(res, err)

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
	})
}

// make sure we can subscribe to a paid plan without a CC if it has trial period
func TestSubscribingToPaidPlanWithWithTrialPeriodHavingNoCC(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withNonFreeTestPlan(func(planID string) {
					createURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCreate)
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					Convey("We should not be able to create a subscription", func() {
						req, err := json.Marshal(&stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     planID,
						})
						tests.ResultedWithNoErrorCheck(req, err)

						_, err = rest.DoRequestWithAuth("POST", createURL, req, sessionID)
						So(err, ShouldNotBeNil)
					})
				})
			})
		})
	})
}

// make sure we can subscribe to 7 days-free plan with more trial period
func TestSubscribingToPaidPlanWithWithDifferentTrialPeriodThanDefault(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				pp := &stripe.PlanParams{
					Amount:        12345,
					Interval:      stripeplan.Month,
					IntervalCount: 1,
					TrialPeriod:   1, // trial for one day
					Name:          fmt.Sprintf("plan for %s", username),
					Currency:      currency.USD,
					ID:            fmt.Sprintf("plan_for_%s", username),
					Statement:     "NAN-FREE",
				}

				plan, err := stripeplan.New(pp)
				So(err, ShouldBeNil)

				addCreditCardToUserWithChecks(endpoint, sessionID)

				createURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCreate)
				deleteURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCancel)
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				req, err := json.Marshal(&stripe.SubParams{
					Customer: group.Payment.Customer.ID,
					Plan:     plan.ID,
					TrialEnd: time.Now().Add(time.Hour * 48).Unix(),
				})
				tests.ResultedWithNoErrorCheck(req, err)

				sub, err := rest.DoRequestWithAuth("POST", createURL, req, sessionID)
				tests.ResultedWithNoErrorCheck(sub, err)

				v := &stripe.Sub{}
				err = json.Unmarshal(sub, v)
				So(err, ShouldBeNil)

				So(v.TrialEnd, ShouldBeGreaterThan, time.Now().Add(time.Hour*24*time.Duration(pp.TrialPeriod)).Unix())

				Convey("We should be able to cancel the subscription", func() {
					res, err := rest.DoRequestWithAuth("DELETE", deleteURL, req, sessionID)
					tests.ResultedWithNoErrorCheck(res, err)

					v := &stripe.Sub{}
					err = json.Unmarshal(res, v)
					So(err, ShouldBeNil)
					So(v.Status, ShouldEqual, "canceled")
				})
			})
		})
	})
}

func TestCancellingSubscriptionCreatesAnotherInvoice(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTrialTestPlan(func(planID string) {
					createURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCreate)
					deleteURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCancel)
					customerUpdateURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					withTestCreditCardToken(func(token string) {
						cp := &stripe.CustomerParams{
							Source: &stripe.SourceParams{
								Token: token,
							},
						}
						req, err := json.Marshal(cp)
						So(err, ShouldBeNil)
						So(req, ShouldNotBeNil)

						res, err := rest.DoRequestWithAuth("POST", customerUpdateURL, req, sessionID)
						So(err, ShouldBeNil)
						So(res, ShouldNotBeNil)

						req, err = json.Marshal(&stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     planID,
						})
						tests.ResultedWithNoErrorCheck(req, err)

						sub, err := rest.DoRequestWithAuth("POST", createURL, req, sessionID)
						tests.ResultedWithNoErrorCheck(sub, err)

						Convey("We should be able to list invoices", func() {
							listInvoicesURL := fmt.Sprintf("%s%s", endpoint, EndpointInvoiceList)
							res, err := rest.DoRequestWithAuth("GET", listInvoicesURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							var invoices []*stripe.Invoice
							err = json.Unmarshal(res, &invoices)
							So(err, ShouldBeNil)
							So(len(invoices), ShouldEqual, 1) // because we only have one invoice

							Convey("We should be able to cancel the subscription", func() {
								res, err := rest.DoRequestWithAuth("DELETE", deleteURL, req, sessionID)
								tests.ResultedWithNoErrorCheck(res, err)

								v := &stripe.Sub{}
								err = json.Unmarshal(res, v)
								So(err, ShouldBeNil)
								So(v.Status, ShouldEqual, "canceled")

								Convey("We should be able to list invoices with startingAfter query param", func() {
									listInvoicesURLWithQuery := fmt.Sprintf("%s%s", endpoint, EndpointInvoiceList)
									res, err = rest.DoRequestWithAuth("GET", listInvoicesURLWithQuery, nil, sessionID)
									tests.ResultedWithNoErrorCheck(res, err)

									var invoices []*stripe.Invoice
									err = json.Unmarshal(res, &invoices)
									So(err, ShouldBeNil)
									So(len(invoices), ShouldEqual, 2)
								})
							})
						})
					})
				})
			})
		})
	})
}

// make sure we cant subscribe to a paid plan without a CC
func TestSubscribingToPaidPlanWithWithNoTrialPeriodHavingNoCC(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withNonFreeTestPlan(func(planID string) {
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					Convey("We should be able to create a subscription", func() {
						req, err := json.Marshal(&stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     planID,
						})
						tests.ResultedWithNoErrorCheck(req, err)

						createURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCreate)
						_, err = rest.DoRequestWithAuth("POST", createURL, req, sessionID)
						So(err, ShouldNotBeNil)
					})
				})
			})
		})
	})
}

func TestAtTheEndOfTrialPeriodSubscriptionStatusIsStillTrialing(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestCreditCardToken(func(token string) {
					req, err := json.Marshal(&stripe.CustomerParams{
						Source: &stripe.SourceParams{
							Token: token,
						},
					})
					tests.ResultedWithNoErrorCheck(req, err)

					res, err := rest.DoRequestWithAuth(
						"POST",
						fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate),
						req,
						sessionID,
					)
					tests.ResultedWithNoErrorCheck(res, err)

					createURL := fmt.Sprintf("%s%s", endpoint, EndpointSubscriptionCreate)
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					pp := &stripe.PlanParams{
						Amount:        12345,
						Interval:      stripeplan.Month,
						IntervalCount: 1,
						TrialPeriod:   1, // trial for one day
						Name:          fmt.Sprintf("plan for %s", username),
						Currency:      currency.USD,
						ID:            fmt.Sprintf("plan_for_%s", username),
						Statement:     "NAN-FREE",
					}
					plan, err := stripeplan.New(pp)
					So(err, ShouldBeNil)
					defer stripeplan.Del(plan.ID)

					req, err = json.Marshal(&stripe.SubParams{
						Customer: group.Payment.Customer.ID,
						Plan:     plan.ID,
					})
					tests.ResultedWithNoErrorCheck(req, err)

					res, err = rest.DoRequestWithAuth("POST", createURL, req, sessionID)
					tests.ResultedWithNoErrorCheck(res, err)

					sub := &stripe.Sub{}
					err = json.Unmarshal(res, sub)
					So(err, ShouldBeNil)

					subParams := &stripe.SubParams{
						Customer: group.Payment.Customer.ID,
						Plan:     plan.ID,
						TrialEnd: time.Now().UTC().Add(time.Second * 60 * 5).Unix(),
					}
					sub, err = stripesub.Update(sub.ID, subParams)
					tests.ResultedWithNoErrorCheck(sub, err)

					sub, err = stripesub.Get(sub.ID, nil)
					tests.ResultedWithNoErrorCheck(sub, err)

					So(sub.Status, ShouldEqual, "trialing")
				})
			})
		})
	})
}
