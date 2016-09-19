package api

import (
	"encoding/json"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"socialapi/workers/payment"
	"testing"

	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
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
						getURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerGet)
						updateURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)

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
							withTestCreditCardToken(func(token string) {
								cp := &stripe.CustomerParams{
									Source: &stripe.SourceParams{
										Token: token,
									},
								}

								req, err := json.Marshal(cp)
								So(err, ShouldBeNil)
								So(req, ShouldNotBeNil)

								res, err := rest.DoRequestWithAuth("POST", updateURL, req, sessionID)
								So(err, ShouldBeNil)
								So(res, ShouldNotBeNil)

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
	})
}

func TestCouponApply(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestCoupon(func(couponID string) {
					Convey("After adding coupon to the user", func() {

						updateURL := fmt.Sprintf("%s%s", endpoint, EndpointCustomerUpdate)

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

func TestInfoActiveUsers(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestPlan(func(planID string) {
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						Convey("We should be able to get info", func() {
							infoURL := fmt.Sprintf("%s%s", endpoint, EndpointInfo)
							res, err := rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							v := &payment.Usage{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)

							Convey("When we add the same member with different role", func() {
								acc, err := modelhelper.GetAccount(username)
								tests.ResultedWithNoErrorCheck(acc, err)

								group, err := modelhelper.GetGroup(groupName)
								tests.ResultedWithNoErrorCheck(group, err)

								err = modelhelper.AddRelationship(&mongomodels.Relationship{
									Id:         bson.NewObjectId(),
									TargetId:   acc.Id,
									TargetName: "JAccount",
									SourceId:   group.Id,
									SourceName: "JGroup",
									As:         "member",
								})
								So(err, ShouldBeNil)

								Convey("It should not be counted twice", func() {
									res, err = rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
									tests.ResultedWithNoErrorCheck(res, err)

									v2 := &payment.Usage{}
									So(json.Unmarshal(res, v2), ShouldBeNil)

									So(v.User.Active, ShouldEqual, v2.User.Active)
									So(v.User.Total, ShouldEqual, v2.User.Total)

									Convey("When we add new member", func() {
										account2 := models.CreateAccountInBothDbsWithCheck()
										acc2, err := modelhelper.GetAccount(account2.Nick)
										tests.ResultedWithNoErrorCheck(acc2, err)

										err = modelhelper.AddRelationship(&mongomodels.Relationship{
											Id:         bson.NewObjectId(),
											TargetId:   acc2.Id,
											TargetName: "JAccount",
											SourceId:   group.Id,
											SourceName: "JGroup",
											As:         "member",
										})
										So(err, ShouldBeNil)

										res, err = rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
										tests.ResultedWithNoErrorCheck(res, err)

										v3 := &payment.Usage{}
										So(json.Unmarshal(res, v3), ShouldBeNil)
										Convey("It should be counted", func() {
											So(v3.User.Active, ShouldBeGreaterThan, v2.User.Active)
											So(v3.User.Total, ShouldBeGreaterThan, v2.User.Total)
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

func TestInfoDeletedUsers(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestPlan(func(planID string) {
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						Convey("We should be able to get info", func() {
							infoURL := fmt.Sprintf("%s%s", endpoint, EndpointInfo)
							res, err := rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							v := &payment.Usage{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)

							Convey("When we add deleted members", func() {
								group, err := modelhelper.GetGroup(groupName)
								tests.ResultedWithNoErrorCheck(group, err)

								account1 := models.CreateAccountInBothDbsWithCheck()
								acc, err := modelhelper.GetAccount(account1.Nick)
								tests.ResultedWithNoErrorCheck(acc, err)
								dm, err := modelhelper.CreateDeletedMember(group.Id, acc.Id)
								tests.ResultedWithNoErrorCheck(dm, err)

								account2 := models.CreateAccountInBothDbsWithCheck()
								acc2, err := modelhelper.GetAccount(account2.Nick)
								tests.ResultedWithNoErrorCheck(acc2, err)
								dm2, err := modelhelper.CreateDeletedMember(group.Id, acc2.Id)
								tests.ResultedWithNoErrorCheck(dm2, err)

								Convey("They should be counted", func() {
									res, err = rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
									tests.ResultedWithNoErrorCheck(res, err)

									v2 := &payment.Usage{}
									So(json.Unmarshal(res, v2), ShouldBeNil)
									So(v2.User.Active, ShouldEqual, v.User.Active)
									So(v2.User.Deleted, ShouldBeGreaterThan, v.User.Deleted)
									So(v2.User.Total, ShouldBeGreaterThan, v.User.Total)

									So(v2.User.Deleted, ShouldEqual, 2)

									Convey("After closing the subscription counts should go back to 0", func() {
										c1, err := modelhelper.GetDeletedMemberCountByGroupId(group.Id)
										tests.ResultedWithNoErrorCheck(c1, err)

										count, err := modelhelper.CalculateAndApplyDeletedMembers(group.Id, subscriptionID)
										tests.ResultedWithNoErrorCheck(count, err)

										So(c1, ShouldEqual, count)

										c2, err := modelhelper.GetDeletedMemberCountByGroupId(group.Id)
										tests.ResultedWithNoErrorCheck(c2, err)
										So(c2, ShouldEqual, 0)

										So(count, ShouldEqual, v2.User.Deleted)

										res, err = rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
										tests.ResultedWithNoErrorCheck(res, err)

										v3 := &payment.Usage{}
										So(json.Unmarshal(res, v3), ShouldBeNil)
										So(v3.User.Deleted, ShouldEqual, 0)
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

func TestInfoDeletedUsersAreNotCounted(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTrialTestPlan(func(planID string) {
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						Convey("We should be able to get info", func() {
							infoURL := fmt.Sprintf("%s%s", endpoint, EndpointInfo)
							res, err := rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							v := &payment.Usage{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)

							Convey("When we add deleted members", func() {
								group, err := modelhelper.GetGroup(groupName)
								tests.ResultedWithNoErrorCheck(group, err)

								account1 := models.CreateAccountInBothDbsWithCheck()
								acc, err := modelhelper.GetAccount(account1.Nick)
								tests.ResultedWithNoErrorCheck(acc, err)
								dm, err := modelhelper.CreateDeletedMember(group.Id, acc.Id)
								tests.ResultedWithNoErrorCheck(dm, err)

								account2 := models.CreateAccountInBothDbsWithCheck()
								acc2, err := modelhelper.GetAccount(account2.Nick)
								tests.ResultedWithNoErrorCheck(acc2, err)
								dm2, err := modelhelper.CreateDeletedMember(group.Id, acc2.Id)
								tests.ResultedWithNoErrorCheck(dm2, err)

								Convey("They should not be counted", func() {
									res, err = rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
									tests.ResultedWithNoErrorCheck(res, err)

									v2 := &payment.Usage{}
									So(json.Unmarshal(res, v2), ShouldBeNil)
									So(v2.User.Active, ShouldEqual, v.User.Active)
									So(v2.User.Deleted, ShouldBeGreaterThan, v.User.Deleted)
									So(v2.User.Total, ShouldEqual, v.User.Total)

									So(v2.User.Total, ShouldEqual, 1)
									So(v2.User.Deleted, ShouldEqual, 2)
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
					withSubscription(endpoint, groupName, sessionID, planID, func(subscriptionID string) {
						Convey("We should be able to get info", func() {
							infoURL := fmt.Sprintf("%s%s", endpoint, EndpointInfo)
							res, err := rest.DoRequestWithAuth("GET", infoURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							v := &payment.Usage{}
							err = json.Unmarshal(res, v)
							So(err, ShouldBeNil)

							So(v.Plan.ID, ShouldEqual, planID)
						})
					})
				})
			})
		})
	})
}
