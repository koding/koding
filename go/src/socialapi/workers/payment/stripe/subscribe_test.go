package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestSubscribe(t *testing.T) {
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

		_, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		err = Subscribe(token, accId, email, "hobbyist_month")
		So(err, ShouldBeNil)

		Convey("Then customer can't subscribe to same plan again", func() {
			err = Subscribe(token, accId, email, "hobbyist_month")
			So(err, ShouldEqual, ErrCustomerAlreadySubscribedToPlan)
		})
	})
}
