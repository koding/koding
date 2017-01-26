package payment

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/tests"
	"socialapi/workers/email/emailsender"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/coupon"
	"github.com/stripe/stripe-go/currency"
	"github.com/stripe/stripe-go/plan"
	"github.com/stripe/stripe-go/token"
	"gopkg.in/mgo.v2/bson"
)

func withStubData(f func(username string, groupName string, sessionID string)) {
	acc, _, groupName := models.CreateRandomGroupDataWithChecks()
	group, err := modelhelper.GetGroup(groupName)
	tests.ResultedWithNoErrorCheck(group, err)

	err = modelhelper.MakeAdmin(bson.ObjectIdHex(acc.OldId), group.Id)
	So(err, ShouldBeNil)

	ses, err := modelhelper.FetchOrCreateSession(acc.Nick, groupName)
	tests.ResultedWithNoErrorCheck(ses, err)

	cus, err := EnsureCustomerForGroup(acc.Nick, groupName, &stripe.CustomerParams{})
	tests.ResultedWithNoErrorCheck(cus, err)

	f(acc.Nick, groupName, ses.ClientId)

	err = DeleteCustomerForGroup(groupName)
	So(err, ShouldBeNil)
}

func TestInvoiceCreatedHandlerStayInTheSamePlan(t *testing.T) {
	testData := `
{
    "id": "in_00000000000000",
    "object": "invoice",
    "amount_due": 0,
    "application_fee": null,
    "attempt_count": 0,
    "attempted": false,
    "charge": null,
    "closed": false,
    "currency": "usd",
    "customer": "%s",
    "date": 1471348722,
    "description": null,
    "discount": null,
    "ending_balance": 0,
    "forgiven": false,
    "livemode": false,
    "metadata": {},
    "next_payment_attempt": null,
    "paid": false,
    "period_end": 1471348722,
    "period_start": 1471348722,
    "receipt_number": null,
    "starting_balance": 0,
    "statement_descriptor": null,
    "subscription": "%s",
    "subtotal": %d,
    "tax": null,
    "tax_percent": null,
    "total": %d,
    "webhooks_delivered_at": 1471348722
}`

	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken
		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				withTestCreditCardToken(func(token string) {
					// attach payment source
					cp := &stripe.CustomerParams{
						Source: &stripe.SourceParams{
							Token: token,
						},
					}

					c, err := UpdateCustomerForGroup(username, groupName, cp)
					tests.ResultedWithNoErrorCheck(c, err)

					const totalMembers = 9
					// generate 9 members
					generateAndAddMembersToGroup(group.Slug, totalMembers)

					// create test plan
					id := "p_" + bson.NewObjectId().Hex()
					pp := &stripe.PlanParams{
						Amount:        GetPlan(General).Amount,
						Interval:      plan.Month,
						IntervalCount: 1,
						TrialPeriod:   0,
						Name:          id,
						Currency:      currency.USD,
						ID:            id,
					}

					p, err := plan.New(pp)
					So(err, ShouldBeNil)

					// subscribe to test plan
					params := &stripe.SubParams{
						Customer: group.Payment.Customer.ID,
						Plan:     p.ID,
						Quantity: totalMembers,
					}

					sub, err := EnsureSubscriptionForGroup(group.Slug, params)
					tests.ResultedWithNoErrorCheck(sub, err)

					// check if group has correct sub id
					groupAfterSub, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(groupAfterSub, err)
					So(sub.ID, ShouldEqual, groupAfterSub.Payment.Subscription.ID)

					Convey("When invoice.created is triggered with right amount of total fee", func() {
						raw := []byte(fmt.Sprintf(
							testData,
							group.Payment.Customer.ID,
							sub.ID,
							GetPlan(General).Amount*totalMembers,
							GetPlan(General).Amount*totalMembers,
						))

						err := invoiceCreatedHandler(raw)
						So(err, ShouldBeNil)

						Convey("subscription id should stay same", func() {
							groupAfterHook, err := modelhelper.GetGroup(groupName)
							tests.ResultedWithNoErrorCheck(groupAfterHook, err)

							// group should have correct sub id
							So(sub.ID, ShouldEqual, groupAfterHook.Payment.Subscription.ID)

							count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
							So(err, ShouldBeNil)
							So(count, ShouldEqual, 0)

							Convey("we should clean up successfully", func() {
								sub, err := DeleteSubscriptionForGroup(group.Slug)
								tests.ResultedWithNoErrorCheck(sub, err)

								_, err = plan.Del(pp.ID)
								So(err, ShouldBeNil)
							})
						})
					})
				})
			})
		})
	})
}

func TestInvoiceCreatedHandlerCustomPlan(t *testing.T) {
	testData := `
{
    "closed": false,
    "paid": false,
    "customer": "%s"
}`

	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken
		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				// create custom test plan
				id := "p_c_" + bson.NewObjectId().Hex()
				pp := &stripe.PlanParams{
					Amount:        GetPlan(General).Amount,
					Interval:      plan.Month,
					IntervalCount: 1,
					TrialPeriod:   1,
					Name:          id,
					Currency:      currency.USD,
					ID:            id,
				}

				p, err := plan.New(pp)
				So(err, ShouldBeNil)

				const totalMembers = 9

				// subscribe to test plan
				params := &stripe.SubParams{
					Customer: group.Payment.Customer.ID,
					Plan:     p.ID,
					Quantity: totalMembers,
				}

				Convey("Even if we process customer with a custom plan we should require CC", func() {
					_, err := EnsureSubscriptionForGroup(group.Slug, params)
					So(err, ShouldEqual, ErrCustomerSourceNotExists)

					Convey("When custom plan holder has CC", func() {
						withTestCreditCardToken(func(token string) {
							// attach payment source
							cp := &stripe.CustomerParams{
								Source: &stripe.SourceParams{
									Token: token,
								},
							}
							c, err := UpdateCustomerForGroup(username, groupName, cp)
							tests.ResultedWithNoErrorCheck(c, err)

							Convey("We should be able to create subscription", func() {
								sub, err := EnsureSubscriptionForGroup(group.Slug, params)
								tests.ResultedWithNoErrorCheck(sub, err)

								// check if group has correct sub id
								groupAfterSub, err := modelhelper.GetGroup(groupName)
								tests.ResultedWithNoErrorCheck(groupAfterSub, err)
								So(sub.ID, ShouldEqual, groupAfterSub.Payment.Subscription.ID)

								Convey("When invoice.created is triggered with custom plan", func() {
									raw := []byte(fmt.Sprintf(
										testData,
										group.Payment.Customer.ID,
									))

									err := invoiceCreatedHandler(raw)
									So(err, ShouldBeNil)

									Convey("subscription id should stay same", func() {
										groupAfterHook, err := modelhelper.GetGroup(groupName)
										tests.ResultedWithNoErrorCheck(groupAfterHook, err)

										// group should have correct sub id
										So(sub.ID, ShouldEqual, groupAfterHook.Payment.Subscription.ID)

										count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
										So(err, ShouldBeNil)
										So(count, ShouldEqual, 0)

										Convey("we should clean up successfully", func() {
											sub, err := DeleteSubscriptionForGroup(group.Slug)
											tests.ResultedWithNoErrorCheck(sub, err)

											_, err = plan.Del(pp.ID)
											So(err, ShouldBeNil)
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

func TestInvoiceCreatedHandlerWithCouponAndAccountBalance(t *testing.T) {
	testData := `
{
    "id": "in_00000000000000",
    "object": "invoice",
    "amount_due": 0,
    "charge": null,
    "closed": false,
    "currency": "usd",
    "customer": "%s",
    "discount":{
      "object": "discount",
      "coupon": {
        "id": "QtadvP4t",
        "object": "coupon",
        "amount_off": %d,
        "created": 1473113335,
        "currency": "usd",
        "duration": "once",
        "valid": true
      },
      "customer": "cus_98mqDLgCNhwhIo",
      "end": null,
      "start": 1473113336,
      "subscription": null
    },
    "date": 1471348722,
    "ending_balance": 0,
    "forgiven": false,
    "livemode": false,
    "metadata": {},
    "next_payment_attempt": null,
    "paid": false,
    "period_end": 1471348722,
    "period_start": 1471348722,
    "receipt_number": null,
    "starting_balance": %d,
    "statement_descriptor": null,
    "subscription": "%s",
    "subtotal": %d,
    "tax": null,
    "tax_percent": null,
    "total": %d,
    "webhooks_delivered_at": 1471348722
}`
	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken
		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				// add credit card to the user
				withTestCreditCardToken(func(token string) {
					var offAmount uint64 = 100
					var offBalance int64 = 200
					withTestCoupon(offAmount, func(couponCode string) {

						// attach payment source
						cp := &stripe.CustomerParams{
							// add our coupon
							Coupon: couponCode,
							// add some credit to user
							Balance: -offBalance,
							// add the CC
							Source: &stripe.SourceParams{
								Token: token,
							},
						}

						c, err := UpdateCustomerForGroup(username, groupName, cp)
						tests.ResultedWithNoErrorCheck(c, err)
						const totalMembers = 9
						// generate 9 members with a total of 1 deleted user (also there is an admin)
						generateAndAddMembersToGroup(group.Slug, totalMembers)

						// create test plan
						id := "p_" + bson.NewObjectId().Hex()
						pp := &stripe.PlanParams{
							Amount:        GetPlan(General).Amount,
							Interval:      plan.Month,
							IntervalCount: 1,
							TrialPeriod:   0,
							Name:          id,
							Currency:      currency.USD,
							ID:            id,
						}

						p, err := plan.New(pp)
						So(err, ShouldBeNil)

						// subscribe to test plan
						params := &stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     p.ID,
							Quantity: totalMembers,
						}

						sub, err := EnsureSubscriptionForGroup(group.Slug, params)
						tests.ResultedWithNoErrorCheck(sub, err)

						// check if group has correct sub id
						groupAfterSub, err := modelhelper.GetGroup(groupName)
						tests.ResultedWithNoErrorCheck(groupAfterSub, err)
						So(sub.ID, ShouldEqual, groupAfterSub.Payment.Subscription.ID)

						Convey("When invoice.created is triggered with right amount of total fee", func() {
							totalDiscount := uint64(offBalance) + offAmount
							raw := []byte(fmt.Sprintf(
								testData,
								group.Payment.Customer.ID,
								offAmount,
								-offBalance,
								sub.ID,
								GetPlan(General).Amount*totalMembers,
								(GetPlan(General).Amount*totalMembers)-(totalDiscount),
							))
							var capturedMails []*emailsender.Mail
							realMailSender := mailSender
							mailSender = func(m *emailsender.Mail) error {
								capturedMails = append(capturedMails, m)
								return nil
							}
							So(invoiceCreatedHandler(raw), ShouldBeNil)
							mailSender = realMailSender

							// this means we didnt change the subscription.
							So(len(capturedMails), ShouldEqual, 0)

							Convey("subscription id should stay same", func() {
								groupAfterHook, err := modelhelper.GetGroup(groupName)
								tests.ResultedWithNoErrorCheck(groupAfterHook, err)

								// group should have correct sub id
								So(sub.ID, ShouldEqual, groupAfterHook.Payment.Subscription.ID)

								count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
								So(err, ShouldBeNil)
								So(count, ShouldEqual, 0)

								Convey("we should clean up successfully", func() {
									sub, err := DeleteSubscriptionForGroup(group.Slug)
									tests.ResultedWithNoErrorCheck(sub, err)

									_, err = plan.Del(pp.ID)
									So(err, ShouldBeNil)
								})
							})
						})
					})
				})
			})
		})
	})
}

func TestInvoiceCreatedHandlerUpgradePlan(t *testing.T) {
	testData := `
{
    "id": "in_00000000000000",
    "object": "invoice",
    "amount_due": 0,
    "application_fee": null,
    "attempt_count": 0,
    "attempted": false,
    "charge": null,
    "closed": false,
    "currency": "usd",
    "customer": "%s",
    "date": 1471348722,
    "description": null,
    "discount": null,
    "ending_balance": 0,
    "forgiven": false,
    "livemode": false,
    "metadata": {},
    "next_payment_attempt": null,
    "paid": false,
    "period_end": 1471348722,
    "period_start": 1471348722,
    "receipt_number": null,
    "starting_balance": 0,
    "statement_descriptor": null,
    "subscription": "%s",
    "subtotal": %d,
    "tax": null,
    "tax_percent": null,
    "total": %d,
    "webhooks_delivered_at": 1471348722
}`

	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken
		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				withTestCreditCardToken(func(token string) {
					// attach payment source
					cp := &stripe.CustomerParams{
						Source: &stripe.SourceParams{
							Token: token,
						},
					}

					c, err := UpdateCustomerForGroup(username, groupName, cp)
					tests.ResultedWithNoErrorCheck(c, err)

					const totalMembers = 1
					generateAndAddMembersToGroup(group.Slug, totalMembers)

					// create test plan
					id := "p_" + bson.NewObjectId().Hex()
					pp := &stripe.PlanParams{
						Amount:        GetPlan(Solo).Amount,
						Interval:      plan.Month,
						IntervalCount: 1,
						TrialPeriod:   0,
						Name:          id,
						Currency:      currency.USD,
						ID:            id,
					}

					p, err := plan.New(pp)
					So(err, ShouldBeNil)

					// subscribe to test plan
					params := &stripe.SubParams{
						Customer: group.Payment.Customer.ID,
						Plan:     p.ID,
						Quantity: totalMembers,
					}

					sub, err := EnsureSubscriptionForGroup(group.Slug, params)
					tests.ResultedWithNoErrorCheck(sub, err)

					// check if group has correct sub id
					groupAfterSub, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(groupAfterSub, err)
					So(sub.ID, ShouldEqual, groupAfterSub.Payment.Subscription.ID)

					// add 1 more user to force plan upgrade
					generateAndAddMembersToGroup(group.Slug, 1)

					Convey("When invoice.created is triggered with previous plan's amount", func() {
						raw := []byte(fmt.Sprintf(
							testData,
							group.Payment.Customer.ID,
							sub.ID,
							GetPlan(General).Amount*totalMembers,
							GetPlan(General).Amount*totalMembers,
						))

						var capturedMails []*emailsender.Mail
						realMailSender := mailSender
						mailSender = func(m *emailsender.Mail) error {
							capturedMails = append(capturedMails, m)
							return nil
						}
						So(invoiceCreatedHandler(raw), ShouldBeNil)
						mailSender = realMailSender

						// check we are sending events on subscription change.
						So(len(capturedMails), ShouldEqual, 1)
						So(capturedMails[0].Subject, ShouldEqual, eventNameJoinedNewPricingTier)
						So(len(capturedMails[0].Properties.Options), ShouldBeGreaterThan, 1)
						oldPlanID := capturedMails[0].Properties.Options["oldPlanID"]
						newPlanID := capturedMails[0].Properties.Options["newPlanID"]
						So(oldPlanID, ShouldNotBeBlank)
						So(newPlanID, ShouldNotBeBlank)
						So(newPlanID, ShouldNotEqual, oldPlanID)

						Convey("subscription id should not stay same", func() {
							groupAfterHook, err := modelhelper.GetGroup(groupName)
							tests.ResultedWithNoErrorCheck(groupAfterHook, err)

							// group should have correct sub id
							So(sub.ID, ShouldNotEqual, groupAfterHook.Payment.Subscription.ID)

							sub, err := GetSubscriptionForGroup(groupName)
							tests.ResultedWithNoErrorCheck(sub, err)

							So(sub.Plan.ID, ShouldEqual, General)

							count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
							So(err, ShouldBeNil)
							So(count, ShouldEqual, 0)

							Convey("we should clean up successfully", func() {
								sub, err := DeleteSubscriptionForGroup(group.Slug)
								tests.ResultedWithNoErrorCheck(sub, err)

								_, err = plan.Del(pp.ID)
								So(err, ShouldBeNil)
							})
						})
					})
				})
			})
		})
	})
}

func TestInvoiceCreatedHandlerDowngradePlan(t *testing.T) {
	testData := `
{
    "id": "in_00000000000000",
    "object": "invoice",
    "amount_due": 0,
    "application_fee": null,
    "attempt_count": 0,
    "attempted": false,
    "charge": null,
    "closed": false,
    "currency": "usd",
    "customer": "%s",
    "date": 1471348722,
    "description": null,
    "discount": null,
    "ending_balance": 0,
    "forgiven": false,
    "livemode": false,
    "metadata": {},
    "next_payment_attempt": null,
    "paid": false,
    "period_end": 1471348722,
    "period_start": 1471348722,
    "receipt_number": null,
    "starting_balance": 0,
    "statement_descriptor": null,
    "subscription": "%s",
    "subtotal": %d,
    "tax": null,
    "tax_percent": null,
    "total": %d,
    "webhooks_delivered_at": 1471348722
}`

	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken
		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				withTestCreditCardToken(func(token string) {
					// attach payment source
					cp := &stripe.CustomerParams{
						Source: &stripe.SourceParams{
							Token: token,
						},
					}

					c, err := UpdateCustomerForGroup(username, groupName, cp)
					tests.ResultedWithNoErrorCheck(c, err)

					const totalMembers = 9
					generateAndAddMembersToGroup(group.Slug, totalMembers)

					// create test plan
					id := "p_" + bson.NewObjectId().Hex()
					pp := &stripe.PlanParams{
						Amount:        GetPlan(General).Amount,
						Interval:      plan.Month,
						IntervalCount: 1,
						TrialPeriod:   0,
						Name:          id,
						Currency:      currency.USD,
						ID:            id,
					}

					p, err := plan.New(pp)
					So(err, ShouldBeNil)

					// subscribe to test plan with more than actual number, simulating having 11 members previous month
					var extraneousCount uint64 = uint64(totalMembers) + 2
					params := &stripe.SubParams{
						Customer: group.Payment.Customer.ID,
						Plan:     p.ID,
						Quantity: extraneousCount,
					}

					sub, err := EnsureSubscriptionForGroup(group.Slug, params)
					tests.ResultedWithNoErrorCheck(sub, err)

					// check if group has correct sub id
					groupAfterSub, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(groupAfterSub, err)
					So(sub.ID, ShouldEqual, groupAfterSub.Payment.Subscription.ID)

					Convey("When invoice.created is triggered with previous plan's amount", func() {
						raw := []byte(fmt.Sprintf(
							testData,
							group.Payment.Customer.ID,
							sub.ID,
							GetPlan(General).Amount*extraneousCount,
							GetPlan(General).Amount*extraneousCount,
						))

						So(invoiceCreatedHandler(raw), ShouldBeNil)

						Convey("subscription id should not stay same", func() {
							groupAfterHook, err := modelhelper.GetGroup(groupName)
							tests.ResultedWithNoErrorCheck(groupAfterHook, err)

							// group should have correct sub id
							So(sub.ID, ShouldNotEqual, groupAfterHook.Payment.Subscription.ID)

							sub, err := GetSubscriptionForGroup(groupName)
							tests.ResultedWithNoErrorCheck(sub, err)

							So(sub.Plan.ID, ShouldEqual, General)

							count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
							So(err, ShouldBeNil)
							So(count, ShouldEqual, 0)

							Convey("we should clean up successfully", func() {
								sub, err := DeleteSubscriptionForGroup(group.Slug)
								tests.ResultedWithNoErrorCheck(sub, err)

								_, err = plan.Del(pp.ID)
								So(err, ShouldBeNil)
							})
						})
					})
				})
			})
		})
	})
}

func TestCustomerSubscriptionCreatedHandler(t *testing.T) {
	testData := `
{
    "id": "sub_94xDGmeKJ35NhI",
    "object": "subscription",
    "application_fee_percent": null,
    "cancel_at_period_end": false,
    "canceled_at": 1472229377,
    "created": 1472229375,
    "current_period_end": 1472229675,
    "current_period_start": 1472229375,
    "customer": "%s",
    "discount": null,
    "ended_at": 1472229377,
    "livemode": false,
    "metadata": {},
    "plan": {
        "id": "my_test_plan",
        "object": "plan",
        "amount": 12345,
        "created": 1472229375,
        "currency": "usd",
        "interval": "month",
        "interval_count": 1,
        "livemode": false,
        "metadata": {},
        "name": "plan for 57c06ffc9bc22b9f5db651c6",
        "statement_descriptor": "NAN-FREE",
        "trial_period_days": 1
    },
    "quantity": 1,
    "start": 1472229376,
    "status": "trialing",
    "tax_percent": null,
    "trial_end": 1472834175,
    "trial_start": 1472229375
}`
	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken

		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				Convey("Then Group should have customer id", func() {
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					So(group.Payment.Customer.ID, ShouldNotBeBlank)

					Convey("When subscription.created is triggered", func() {
						raw := []byte(fmt.Sprintf(testData, group.Payment.Customer.ID))

						var capturedMails []*emailsender.Mail

						realMailSender := mailSender
						mailSender = func(m *emailsender.Mail) error {
							capturedMails = append(capturedMails, m)
							return nil
						}
						err := customerSubscriptionCreatedHandler(raw)
						So(err, ShouldBeNil)
						mailSender = realMailSender
						Convey("properties of event should be set accordingly", func() {
							So(len(capturedMails), ShouldEqual, 2)
							So(capturedMails[0].Subject, ShouldEqual, "subscribed to my_test_plan plan")
							So(capturedMails[1].Subject, ShouldEqual, "seven days trial started")
						})
					})
				})
			})
		})
	})
}

func TestCustomerSourceCreatedHandler(t *testing.T) {
	testData := `
{
      "id": "card_00000000000000",
      "object": "card",
      "address_city": null,
      "address_country": null,
      "address_line1": null,
      "address_line1_check": null,
      "address_line2": null,
      "address_state": null,
      "address_zip": null,
      "address_zip_check": null,
      "brand": "Visa",
      "country": "US",
      "customer": "%s",
      "cvc_check": null,
      "dynamic_last4": null,
      "exp_month": 10,
      "exp_year": 2020,
      "funding": "credit",
      "last4": "4242",
      "metadata": {},
      "name": null,
      "tokenization_method": null,
      "fingerprint": "VLZ7tf1OXmWI4TVF"
}`
	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken

		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				Convey("Then Group should have customer id", func() {
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					So(group.Payment.Customer.ID, ShouldNotBeBlank)

					Convey("When customer.source.created is triggered", func() {
						raw := []byte(fmt.Sprintf(testData, group.Payment.Customer.ID))

						var capturedMails []*emailsender.Mail

						realMailSender := mailSender
						mailSender = func(m *emailsender.Mail) error {
							capturedMails = append(capturedMails, m)
							return nil
						}
						err := customerSourceCreatedHandler(raw)
						So(err, ShouldBeNil)
						mailSender = realMailSender
						Convey("properties of event should be set accordingly", func() {
							So(len(capturedMails), ShouldEqual, 1)
							So(capturedMails[0].Subject, ShouldEqual, "entered credit card")
						})
					})
				})
			})
		})
	})
}

func TestInvoiceCreatedHandlerWithZeroUser(t *testing.T) {
	testData := `
{
    "id": "in_00000000000000",
    "object": "invoice",
    "amount_due": 0,
    "application_fee": null,
    "attempt_count": 0,
    "attempted": false,
    "charge": null,
    "closed": false,
    "currency": "usd",
    "customer": "%s",
    "date": 1471348722,
    "description": null,
    "discount": null,
    "ending_balance": 0,
    "forgiven": false,
    "livemode": false,
    "metadata": {},
    "next_payment_attempt": null,
    "paid": false,
    "period_end": 1471348722,
    "period_start": 1471348722,
    "receipt_number": null,
    "starting_balance": 0,
    "statement_descriptor": null,
    "subscription": "%s",
    "subtotal": %d,
    "tax": null,
    "tax_percent": null,
    "total": %d,
    "webhooks_delivered_at": 1471348722
}`

	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken
		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				withNonFreeTestPlan(func(planID string) {
					withTestCreditCardToken(func(token string) {
						group, err := modelhelper.GetGroup(groupName)
						tests.ResultedWithNoErrorCheck(group, err)
						// attach payment source
						cp := &stripe.CustomerParams{
							Source: &stripe.SourceParams{Token: token},
						}
						c, err := UpdateCustomerForGroup(username, groupName, cp)
						tests.ResultedWithNoErrorCheck(c, err)

						// this is just a random number
						const totalMembers = 4
						// subscribe to test plan
						params := &stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     planID,
							Quantity: totalMembers,
						}

						sub, err := EnsureSubscriptionForGroup(group.Slug, params)
						tests.ResultedWithNoErrorCheck(sub, err)

						// check if group has correct sub id
						groupAfterSub, err := modelhelper.GetGroup(groupName)
						tests.ResultedWithNoErrorCheck(groupAfterSub, err)
						So(sub.ID, ShouldEqual, groupAfterSub.Payment.Subscription.ID)

						count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
						So(err, ShouldBeNil)
						So(count, ShouldEqual, 0)

						Convey("When invoice.created is triggered with previous plan's amount", func() {
							raw := []byte(fmt.Sprintf(
								testData,
								group.Payment.Customer.ID,
								sub.ID,
								GetPlan(General).Amount*totalMembers,
								GetPlan(General).Amount*totalMembers,
							))

							So(invoiceCreatedHandler(raw), ShouldBeNil)
							Convey("subscription id should not stay same", func() {
								groupAfterHook, err := modelhelper.GetGroup(groupName)
								tests.ResultedWithNoErrorCheck(groupAfterHook, err)

								// group should have correct sub id
								So(sub.ID, ShouldNotEqual, groupAfterHook.Payment.Subscription.ID)

								sub, err := GetSubscriptionForGroup(groupName)
								tests.ResultedWithNoErrorCheck(sub, err)

								So(sub.Plan.ID, ShouldEqual, Free)

								count, err := (&models.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
								So(err, ShouldBeNil)
								So(count, ShouldEqual, 0)
							})
						})
					})
				})
			})
		})
	})
}

func TestInvoiceHandlers(t *testing.T) {
	testData := `
{
    "id": "in_00000000000000",
    "object": "invoice",
    "amount_due": 100,
    "currency": "usd",
    "customer": %q
}`

	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken

		Convey("Given stub data", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				Convey("Then Group should have customer id", func() {
					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)
					Convey("When invoice handlers are triggered", func() {
						var invoice *stripe.Invoice
						raw := fmt.Sprintf(testData, group.Payment.Customer.ID)
						err := json.Unmarshal([]byte(raw), &invoice)
						So(err, ShouldBeNil)

						var capturedMails []*emailsender.Mail

						realMailSender := mailSender
						mailSender = func(m *emailsender.Mail) error {
							capturedMails = append(capturedMails, m)
							return nil
						}

						eventName := "test event name"
						err = sendInvoiceEvent(invoice, eventName)
						So(err, ShouldBeNil)
						mailSender = realMailSender
						Convey("properties of event should be set accordingly", func() {
							So(len(capturedMails), ShouldEqual, 1)
							So(capturedMails[0].Subject, ShouldEqual, eventName)
						})
					})
				})
			})
		})
	})
}

func withNonFreeTestPlan(f func(planID string)) {
	pp := &stripe.PlanParams{
		Amount:        12345,
		Interval:      plan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "If only that much free",
		Currency:      currency.USD,
		ID:            "p_" + bson.NewObjectId().Hex(),
		Statement:     "NAN-FREE",
	}

	_, err := plan.New(pp)
	So(err, ShouldBeNil)

	f(pp.ID)

	_, err = plan.Del(pp.ID)
	So(err, ShouldBeNil)
}

func generateAndAddMembersToGroup(groupSlug string, count int) {
	// generate members
	for i := 0; i < count; i++ {
		account := models.CreateAccountInBothDbsWithCheck()
		p := models.NewPresenceDaily()
		p.AccountId = account.GetId()
		p.GroupName = groupSlug
		So(p.Create(), ShouldBeNil)
	}
}

func withTestCreditCardToken(f func(token string)) {
	t, err := token.New(&stripe.TokenParams{
		Card: &stripe.CardParams{
			Number: "4242424242424242",
			Month:  "12",
			Year:   "2020",
			CVC:    "123",
		},
	})
	tests.ResultedWithNoErrorCheck(t, err)
	f(t.ID)
}

func withTestCoupon(amount uint64, f func(string)) {
	c, err := coupon.New(&stripe.CouponParams{
		Amount:   amount,
		Duration: "once",
		Currency: "usd",
	})
	So(err, ShouldBeNil)
	So(c, ShouldNotBeNil)
	f(c.ID)
	c1, err := coupon.Del(c.ID)
	So(err, ShouldBeNil)
	So(c1, ShouldNotBeNil)
	So(c1.Deleted, ShouldBeTrue)
}
