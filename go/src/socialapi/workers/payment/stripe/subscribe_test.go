package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripe "github.com/stripe/stripe-go"
	stripeSub "github.com/stripe/stripe-go/sub"
	stripeToken "github.com/stripe/stripe-go/token"
)

func TestSubscribe(t *testing.T) {
	Convey("Given nonexistent plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := Subscribe(token, accId, email, "random_plans", "random_interval")

		Convey("Then it should throw error", func() {
			So(err, ShouldEqual, ErrPlanNotFound)
		})
	})

	Convey("Given nonexistent customer, plan", t,
		subscribeFn(func(token, accId, email string) {
			customerModel, err := FindCustomerByOldId(accId)
			id := customerModel.ProviderCustomerId

			So(err, ShouldBeNil)
			So(customerModel, ShouldNotBeNil)

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(accId), ShouldBeTrue)
			})

			Convey("Then it should create an customer in Stripe", func() {
				So(checkCustomerExistsInStripe(id), ShouldBeTrue)
			})

			Convey("Then it should subscribe user to plan", func() {
				customer, err := GetCustomerFromStripe(id)
				So(err, ShouldBeNil)

				So(customer.Subs.Count, ShouldEqual, 1)
			})

			Convey("Then customer can't subscribe to same plan again", func() {
				err = Subscribe(token, accId, email, StartingPlan, StartingInterval)
				So(err, ShouldEqual, ErrCustomerAlreadySubscribedToPlan)
			})
		}),
	)

	Convey("Given customer already subscribed to a plan", t,
		existingSubscribeFn(func(token, accId, email string) {
			customerModel, err := FindCustomerByOldId(accId)
			So(err, ShouldBeNil)

			id := customerModel.ProviderCustomerId

			Convey("Then it should subscribe user to plan", func() {
				customer, err := GetCustomerFromStripe(id)
				So(err, ShouldBeNil)

				So(customer.Subs.Count, ShouldEqual, 1)
			})
		}),
	)

	Convey("Given customer already subscribed to a plan", t,
		existingSubscribeFn(func(token, accId, email string) {
			customer, err := FindCustomerByOldId(accId)
			So(err, ShouldBeNil)

			customerId := customer.ProviderCustomerId

			subs, err := FindCustomerActiveSubscriptions(customer)
			So(err, ShouldBeNil)

			So(len(subs), ShouldEqual, 1)

			currentSub := subs[0]
			subId := currentSub.ProviderSubscriptionId

			Convey("Then customer can't subscribe to same plan again", func() {
				err = Subscribe(token, accId, email, StartingPlan, StartingInterval)
				So(err, ShouldEqual, ErrCustomerAlreadySubscribedToPlan)
			})

			Convey("When customer upgrades to higher plan", func() {
				err = Subscribe(token, accId, email, HigherPlan, HigherInterval)
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
					newPlan, err := FindPlanByTitleAndInterval(HigherPlan, HigherInterval)

					So(err, ShouldBeNil)
					So(currentSub.PlanId, ShouldEqual, newPlan.Id)
				})
			})
		}),
	)

	Convey("Given customer already subscribed to a plan", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := FindCustomerByOldId(accId)
			So(err, ShouldBeNil)

			customerId := customer.ProviderCustomerId

			subs, err := FindCustomerActiveSubscriptions(customer)
			So(err, ShouldBeNil)

			So(len(subs), ShouldEqual, 1)

			currentSub := subs[0]
			subId := currentSub.ProviderSubscriptionId

			Convey("When customer downgrades to lower plan", func() {
				err = Subscribe(token, accId, email, LowerPlan, LowerInterval)
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
					newPlan, err := FindPlanByTitleAndInterval(LowerPlan, LowerInterval)

					So(err, ShouldBeNil)
					So(currentSub.PlanId, ShouldEqual, newPlan.Id)
				})
			})
		}),
	)

	Convey("Given customer already subscribed to a plan", t,
		subscribeFn(func(token, accId, email string) {
			Convey("When customer downgrades to free plan", func() {
				err := Subscribe(token, accId, email, FreePlan, FreeInterval)
				So(err, ShouldBeNil)

				Convey("Then subscription is canceled", func() {
					customer, err := FindCustomerByOldId(accId)
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

	Convey("Given an existent customer, but no subscription", t,
		subscribeFn(func(token, accId, email string) {
			Convey("When customer upgrades to plan", func() {
				err := Subscribe(token, accId, email, FreePlan, FreeInterval)
				So(err, ShouldBeNil)

				tokenParams := &stripe.TokenParams{
					Card: &stripe.CardParams{
						Number: "4012888888881881",
						Month:  "10",
						Year:   "20",
					},
				}

				token, err := stripeToken.New(tokenParams)
				So(err, ShouldBeNil)

				err = Subscribe(token.Id, accId, email, StartingPlan, StartingInterval)
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
