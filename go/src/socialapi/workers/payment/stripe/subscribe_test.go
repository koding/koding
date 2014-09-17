package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripe "github.com/stripe/stripe-go"
	stripeSub "github.com/stripe/stripe-go/sub"
)

func TestSubscribe(t *testing.T) {
	Convey("Given nonexistent plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := Subscribe(token, accId, email, "random_plans")

		So(err, ShouldEqual, ErrPlanNotFound)
	})

	Convey("Given nonexistent customer, plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := Subscribe(token, accId, email, "hobbyist_month")

		So(err, ShouldBeNil)

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
			err = Subscribe(token, accId, email, "hobbyist_month")
			So(err, ShouldEqual, ErrCustomerAlreadySubscribedToPlan)
		})
	})

	Convey("Given existent customer, plan", t, func() {
		token, accId, email := generateFakeUserInfo()

		_, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		err = Subscribe(token, accId, email, "hobbyist_month")
		So(err, ShouldBeNil)

		customerModel, err := FindCustomerByOldId(accId)
		id := customerModel.ProviderCustomerId

		Convey("Then it should subscribe user to plan", func() {
			customer, err := GetCustomerFromStripe(id)
			So(err, ShouldBeNil)

			So(customer.Subs.Count, ShouldEqual, 1)
		})
	})

	Convey("Given customer already subscribed to a plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		planId := "hobbyist_month"

		_, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		err = Subscribe(token, accId, email, planId)
		So(err, ShouldBeNil)

		customer, err := FindCustomerByOldId(accId)
		So(err, ShouldBeNil)

		customerId := customer.ProviderCustomerId

		subs, err := FindCustomerActiveSubscriptions(customer)
		So(err, ShouldBeNil)

		So(len(subs), ShouldEqual, 1)

		currentSub := subs[0]
		subId := currentSub.ProviderSubscriptionId

		Convey("Then customer can't subscribe to same plan again", func() {
			err = Subscribe(token, accId, email, planId)
			So(err, ShouldEqual, ErrCustomerAlreadySubscribedToPlan)
		})

		Convey("When customer upgrades to higher plan", func() {
			newPlanId := "developer_month"

			err = Subscribe(token, accId, email, newPlanId)
			So(err, ShouldBeNil)

			Convey("Then subscription is updated on stripe", func() {
				subParams := &stripe.SubParams{Customer: customerId}
				sub, err := stripeSub.Get(subId, subParams)

				So(err, ShouldBeNil)

				So(sub.Plan.Id, ShouldEqual, newPlanId)
			})

			Convey("Then subscription is saved", func() {
				subs, err := FindCustomerActiveSubscriptions(customer)
				So(err, ShouldBeNil)

				So(len(subs), ShouldEqual, 1)

				currentSub := subs[0]
				newPlan, err := FindPlanByTitle(newPlanId)

				So(err, ShouldBeNil)
				So(currentSub.PlanId, ShouldEqual, newPlan.Id)
			})
		})
	})

	Convey("Given customer already subscribed to a plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		planId := "professional_month"

		_, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		err = Subscribe(token, accId, email, planId)
		So(err, ShouldBeNil)

		customer, err := FindCustomerByOldId(accId)
		So(err, ShouldBeNil)

		customerId := customer.ProviderCustomerId

		subs, err := FindCustomerActiveSubscriptions(customer)
		So(err, ShouldBeNil)

		So(len(subs), ShouldEqual, 1)

		currentSub := subs[0]
		subId := currentSub.ProviderSubscriptionId

		Convey("When customer downgrades to lower plan", func() {
			newPlanId := "hobbyist_month"

			err = Subscribe(token, accId, email, newPlanId)
			So(err, ShouldBeNil)

			Convey("Then subscription is updated on stripe", func() {
				subParams := &stripe.SubParams{Customer: customerId}
				sub, err := stripeSub.Get(subId, subParams)

				So(err, ShouldBeNil)

				So(sub.Plan.Id, ShouldEqual, newPlanId)
			})

			Convey("Then subscription is saved", func() {
				subs, err := FindCustomerActiveSubscriptions(customer)
				So(err, ShouldBeNil)

				So(len(subs), ShouldEqual, 1)

				currentSub := subs[0]
				newPlan, err := FindPlanByTitle(newPlanId)

				So(err, ShouldBeNil)
				So(currentSub.PlanId, ShouldEqual, newPlan.Id)
			})
		})
	})
}
