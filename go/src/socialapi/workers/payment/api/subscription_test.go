package api

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"socialapi/workers/payment"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"

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
						updateURL := endpoint + EndpointCustomerUpdate
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
							getURL := endpoint + EndpointSubscriptionGet
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
						updateURL := endpoint + EndpointCustomerUpdate

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
								getURL := endpoint + EndpointSubscriptionGet
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
					createURL := endpoint + EndpointSubscriptionCreate
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

				createURL := endpoint + EndpointSubscriptionCreate
				deleteURL := endpoint + EndpointSubscriptionCancel
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
					createURL := endpoint + EndpointSubscriptionCreate
					deleteURL := endpoint + EndpointSubscriptionCancel
					customerUpdateURL := endpoint + EndpointCustomerUpdate

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
							listInvoicesURL := endpoint + EndpointInvoiceList
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
									listInvoicesURLWithQuery := endpoint + EndpointInvoiceList
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

func TestCancellingSubscriptionRemovesPresenceInfo(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTrialTestPlan(func(planID string) {
					addCreditCardToUserWithChecks(endpoint, sessionID)

					acc := models.NewAccount()
					So(acc.ByNick(username), ShouldBeNil)

					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					// create and cancel sub, because we will resubscribe again.
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)

						So((&models.PresenceDaily{
							AccountId: acc.Id,
							GroupName: groupName,
							CreatedAt: time.Now().UTC().Add(-time.Millisecond * 100),
						}).Create(), ShouldBeNil)

						// presence should work properly
						count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(groupName)
						tests.ResultedWithNoErrorCheck(count, err)
						So(count, ShouldEqual, 1)
					})

					// make sure we have zero-ed the count. using bare functions
					// because we wont be getting info when there isnt a sub
					count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(groupName) // check for std
					So(err, ShouldBeNil)
					So(count, ShouldEqual, 0)

					processedCount, err := (&models.PresenceDaily{}).CountDistinctProcessedByGroupName(groupName) // check for processed
					So(err, ShouldBeNil)
					So(processedCount, ShouldEqual, 0)

					// create the sub again and check for the usage info.
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)

						count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(groupName)
						tests.ResultedWithNoErrorCheck(count, err)

						So((&models.PresenceDaily{
							AccountId: acc.Id,
							GroupName: groupName,
							CreatedAt: time.Now().UTC().Add(-time.Millisecond * 100),
						}).Create(), ShouldBeNil)

						// info should work properly
						info, err := payment.EnsureInfoForGroup(group, username)
						tests.ResultedWithNoErrorCheck(info, err)
						So(info.User.Total, ShouldEqual, 1)
						So(info.Trial.User.Total, ShouldEqual, 0)
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

						createURL := endpoint + EndpointSubscriptionCreate
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
				addCreditCardToUserWithChecks(endpoint, sessionID)

				createURL := endpoint + EndpointSubscriptionCreate
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

				req, err := json.Marshal(&stripe.SubParams{
					Customer: group.Payment.Customer.ID,
					Plan:     plan.ID,
				})
				tests.ResultedWithNoErrorCheck(req, err)

				res, err := rest.DoRequestWithAuth("POST", createURL, req, sessionID)
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
}

func TestResubscribingBeforeTrialEndsSubstractsPreviousUsage(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTrialTestPlan(func(planID string) {
					addCreditCardToUserWithChecks(endpoint, sessionID)

					var firstSub *stripe.Sub
					// create and cancel sub, because we will resubscribe again.
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)
						firstSub = sub
					})

					travelInTimeForGroupID(groupName, -time.Hour*24*2)

					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)
						So(sub.TrialEnd, ShouldBeLessThan, firstSub.TrialEnd)
						So(sub.TrialEnd, ShouldBeLessThan, firstSub.TrialEnd+int64(time.Hour*24))

						So(sub.Status, ShouldEqual, "trialing")
					})
				})
			})
		})
	})
}

func TestResubscribingAfterTrialEndsChargesUser(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTrialTestPlan(func(planID string) {
					addCreditCardToUserWithChecks(endpoint, sessionID)

					// create and cancel sub, because we will resubscribe again.
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)
					})

					travelInTimeForGroupID(groupName, -time.Hour*24*31) // trial period is 30 days

					acc := models.NewAccount()
					So(acc.ByNick(username), ShouldBeNil)

					p1 := &models.PresenceDaily{
						AccountId: acc.Id,
						GroupName: groupName,
						CreatedAt: time.Now().UTC().Add(-time.Millisecond * 100),
					}
					So(p1.Create(), ShouldBeNil)

					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)
						So(sub.TrialEnd, ShouldBeLessThan, time.Now().UTC().Unix())
						So(sub.Status, ShouldEqual, "active")
					})
				})
			})
		})
	})
}

func TestResubscribingAfterTrialEndsChargesUserWithoutPresenceInfo(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTrialTestPlan(func(planID string) {
					addCreditCardToUserWithChecks(endpoint, sessionID)

					var firstSub *stripe.Sub
					// create and cancel sub, because we will resubscribe again.
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)
						firstSub = sub
					})

					travelInTimeForGroupID(groupName, -time.Hour*24*31) // trial period is 30 days

					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						sub, err := stripesub.Get(subscriptionID, nil)
						tests.ResultedWithNoErrorCheck(sub, err)
						So(sub.TrialEnd, ShouldBeLessThan, time.Now().UTC().Unix())
						So(sub.Status, ShouldEqual, "active")
					})
				})
			})
		})
	})
}

func travelInTimeForGroupID(groupName string, dur time.Duration) {
	group, err := modelhelper.GetGroup(groupName)
	tests.ResultedWithNoErrorCheck(group, err)

	oldID := group.Id
	newID := bson.NewObjectIdWithTime(group.Id.Time().Add(dur))

	// change team's creation time by changing it's mongo id.
	So(modelhelper.RemoveGroup(group.Id), ShouldBeNil)
	group.Id = newID
	So(modelhelper.CreateGroup(group), ShouldBeNil)
	group, err = modelhelper.GetGroup(groupName)
	tests.ResultedWithNoErrorCheck(group, err)
	So(newID.Hex(), ShouldEqual, group.Id.Hex())

	// all relationships should be updated.
	So(modelhelper.UpdateRelationships(
		modelhelper.Selector{
			"sourceId": oldID,
		}, modelhelper.Selector{
			"$set": modelhelper.Selector{"sourceId": newID}},
	), ShouldBeNil)
}
