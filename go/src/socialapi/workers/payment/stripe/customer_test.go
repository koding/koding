package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripeCustomer "github.com/stripe/stripe-go/customer"
)

func TestCreateAndFindCustomer(t *testing.T) {
	Convey("Given a description (id) and email", t, func() {
		token, accId, email := generateFakeUserInfo()

		customer, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		stripeCustomerId := customer.ProviderCustomerId

		Convey("Then it should create an customer in Stripe", func() {
			custFromStripe, err := stripeCustomer.Get(stripeCustomerId, nil)

			So(err, ShouldBeNil)
			So(custFromStripe.Id, ShouldEqual, stripeCustomerId)
		})

		Convey("Then it should save customer", func() {
			customerModel, err := FindCustomerByOldId(accId)

			So(err, ShouldBeNil)
			So(customerModel, ShouldNotBeNil)

			So(customerModel.OldId, ShouldEqual, accId)
		})
	})
}
