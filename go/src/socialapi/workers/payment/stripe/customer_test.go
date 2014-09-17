package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateAndFindCustomer(t *testing.T) {
	Convey("Given a description (id) and email", t, func() {
		token, accId, email := generateFakeUserInfo()

		customer, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		Convey("Then it should create an customer in Stripe", func() {
			stripeCustomerId := customer.ProviderCustomerId
			So(checkCustomerExistsInStripe(stripeCustomerId), ShouldBeTrue)
		})

		Convey("Then it should save customer", func() {
			So(checkCustomerIsSaved(accId), ShouldBeTrue)
		})
	})
}
