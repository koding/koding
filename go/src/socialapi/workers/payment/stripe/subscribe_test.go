package stripe

import (
	"gopkg.in/mgo.v2/bson"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"

	stripe "github.com/stripe/stripe-go"
	stripeSub "github.com/stripe/stripe-go/sub"
	stripeToken "github.com/stripe/stripe-go/token"
)

func TestSubscribe1(t *testing.T) {
	Convey("Given nonexistent plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := SubscribeForAccount(token, accId, email, "random_plans", "random_interval")

		Convey("Then it should throw error", func() {
			So(err, ShouldEqual, paymenterrors.ErrPlanNotFound)
		})
	})
}

func TestSubscribe2(t *testing.T) {
	Convey("Given nonexistent customer, plan", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			id := customer.ProviderCustomerId

			So(err, ShouldBeNil)
			So(customer, ShouldNotBeNil)

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(accId), ShouldBeTrue)
			})

			Convey("Then it should create an customer in Stripe", func() {
				So(checkCustomerExistsInStripe(id), ShouldBeTrue)
			})

			Convey("Then it should subscribe user to plan", func() {
				customer, err := GetCustomer(id)
				So(err, ShouldBeNil)

				So(customer.Subs.Count, ShouldEqual, 1)
			})

			Convey("Then customer can't subscribe to same plan again", func() {
				err = SubscribeForAccount(token, accId, email, StartingPlan, StartingInterval)
				So(err, ShouldEqual, paymenterrors.ErrCustomerAlreadySubscribedToPlan)
			})
		}),
	)
}

func TestSubscribe3(t *testing.T) {
	Convey("Given customer already subscribed to a plan", t,
		existingSubscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)

			id := customer.ProviderCustomerId

			Convey("Then it should subscribe user to plan", func() {
				customer, err := GetCustomer(id)
				So(err, ShouldBeNil)

				So(customer.Subs.Count, ShouldEqual, 1)
			})
		}),
	)
}

func TestSubscribe4(t *testing.T) {
	Convey("Given customer already subscribed to a plan", t,
		existingSubscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)

			customerId := customer.ProviderCustomerId

			subs, err := FindCustomerActiveSubscriptions(customer)
			So(err, ShouldBeNil)

			So(len(subs), ShouldEqual, 1)

			currentSub := subs[0]
			subId := currentSub.ProviderSubscriptionId

			Convey("Then customer can't subscribe to same plan again", func() {
				err = SubscribeForAccount(token, accId, email, StartingPlan, StartingInterval)
				So(err, ShouldEqual, paymenterrors.ErrCustomerAlreadySubscribedToPlan)
			})

			Convey("When customer upgrades to higher plan", func() {
				err = SubscribeForAccount(token, accId, email, HigherPlan, HigherInterval)
				So(err, ShouldBeNil)

				Convey("Then subscription is updated on stripe", func() {
					subParams := &stripe.SubParams{Customer: customerId}
					sub, err := stripeSub.Get(subId, subParams)

					So(err, ShouldBeNil)

					So(sub.Plan.Id, ShouldEqual, HigherPlan+"_"+HigherInterval)
				})

				Convey("Then subscription is saved", func() {
					subs, err := FindCustomerActiveSubscriptions(customer)
					So(err, ShouldBeNil)

					So(len(subs), ShouldEqual, 1)

					currentSub := subs[0]
					newPlan, err := FindPlanByTitleAndInterval(HigherPlan, HigherInterval, paymentmodels.AccountCustomer)

					So(err, ShouldBeNil)
					So(currentSub.PlanId, ShouldEqual, newPlan.Id)
				})
			})
		}),
	)
}

func TestSubscribe5(t *testing.T) {
	Convey("Given customer already subscribed to a plan", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)

			customerId := customer.ProviderCustomerId

			subs, err := FindCustomerActiveSubscriptions(customer)
			So(err, ShouldBeNil)

			So(len(subs), ShouldEqual, 1)

			currentSub := subs[0]
			subId := currentSub.ProviderSubscriptionId

			Convey("When customer downgrades to lower plan", func() {
				err = SubscribeForAccount(token, accId, email, LowerPlan, LowerInterval)
				So(err, ShouldBeNil)

				Convey("Then subscription is updated on stripe", func() {
					subParams := &stripe.SubParams{Customer: customerId}
					sub, err := stripeSub.Get(subId, subParams)

					So(err, ShouldBeNil)

					So(sub.Plan.Id, ShouldEqual, LowerPlan+"_"+LowerInterval)
				})

				Convey("Then subscription is saved", func() {
					subs, err := FindCustomerActiveSubscriptions(customer)
					So(err, ShouldBeNil)

					So(len(subs), ShouldEqual, 1)

					currentSub := subs[0]
					newPlan, err := FindPlanByTitleAndInterval(LowerPlan, LowerInterval, paymentmodels.AccountCustomer)

					So(err, ShouldBeNil)
					So(currentSub.PlanId, ShouldEqual, newPlan.Id)
				})
			})
		}),
	)
}

func TestSubscribe6(t *testing.T) {
	Convey("Given customer already subscribed to a plan", t,
		subscribeFn(func(token, accId, email string) {
			Convey("When customer downgrades to free plan", func() {
				err := SubscribeForAccount(token, accId, email, FreePlan, FreeInterval)
				So(err, ShouldBeNil)

				Convey("Then subscription is canceled", func() {
					customer, err := paymentmodels.NewCustomer().ByOldId(accId)
					So(err, ShouldBeNil)

					subs, err := FindCustomerActiveSubscriptions(customer)
					So(err, ShouldBeNil)

					So(len(subs), ShouldEqual, 0)
				})

				Convey("Then customer's credit card is deleted", func() {
					resp, err := GetCreditCard(accId)
					So(err, ShouldBeNil)

					So(resp.LastFour, ShouldEqual, "")
				})
			})
		}),
	)
}

func TestSubscribe7(t *testing.T) {
	Convey("Given an existent customer, but no subscription", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)

			sub, err := customer.FindActiveSubscription()
			So(err, ShouldBeNil)

			err = CancelSubscriptionAndRemoveCC(customer, sub)
			So(err, ShouldBeNil)

			Convey("When customer upgrades to plan", func() {
				tokenParams := &stripe.TokenParams{
					Card: &stripe.CardParams{
						Number: "4012888888881881",
						Month:  "10",
						Year:   "20",
					},
				}

				token, err := stripeToken.New(tokenParams)
				So(err, ShouldBeNil)

				err = SubscribeForAccount(token.Id, accId, email, StartingPlan, StartingInterval)
				So(err, ShouldBeNil)

				Convey("Then the customer has new credit card", func() {
					resp, err := GetCreditCard(accId)
					So(err, ShouldBeNil)

					So(resp.LastFour, ShouldEqual, "1881")
				})
			})
		}),
	)
}

func TestSubscribe8(t *testing.T) {
	Convey("Given nonexistent customer, plan", t, func() {
		_, accId, email := generateFakeUserInfo()

		tokenParams := &stripe.TokenParams{
			Card: &stripe.CardParams{
				Number: "4000000000000341", // Attaching this card to a Customer object will succeed, but attempts to charge the customer will fail.
				Month:  "10",
				Year:   "20",
			},
		}

		token, err := stripeToken.New(tokenParams)
		So(err, ShouldBeNil)

		Convey("When customer buys plan with credit card that'll decline", func() {
			err := SubscribeForAccount(token.Id, accId, email, StartingPlan, StartingInterval)

			Convey("Then it should throw error", func() {
				So(err, ShouldNotBeNil)
			})

			Convey("Then customer should be deleted", func() {
				_, err := paymentmodels.NewCustomer().ByOldId(accId)
				So(err, ShouldEqual, paymenterrors.ErrCustomerNotFound)
			})
		})
	})
}

func TestGroupSubscribe1(t *testing.T) {
	Convey("Given nonexistent customer, plan", t,
		subscribeGroupFn(func(token, groupId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(groupId)
			id := customer.ProviderCustomerId

			So(err, ShouldBeNil)
			So(customer, ShouldNotBeNil)

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(groupId), ShouldBeTrue)
			})

			Convey("Then it should create an customer in Stripe", func() {
				So(checkCustomerExistsInStripe(id), ShouldBeTrue)
			})

			Convey("Then it should subscribe user to plan", func() {
				customer, err := GetCustomer(id)
				So(err, ShouldBeNil)

				So(customer.Subs.Count, ShouldEqual, 1)
			})
		}),
	)
}

func TestGroupSubscribe2(t *testing.T) {
	Convey("Given nonexistent customer, plan", t, func() {
		token, gId, email := generateFakeUserInfo()
		group := &models.Group{
			Id:   bson.ObjectIdHex(gId),
			Slug: token[0:10],
		}
		err := modelhelper.CreateGroup(group)
		So(err, ShouldBeNil)

		Convey("When customer tries to buy solo plan", func() {
			err := SubscribeForGroup(token, gId, email, StartingPlan, StartingInterval)

			Convey("Then it should throw error", func() {
				So(err, ShouldEqual, paymenterrors.ErrPlanNotFound)
			})
		})
	})
}
