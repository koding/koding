package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

//----------------------------------------------------------
// Crud tests
//----------------------------------------------------------

func TestCreateAndFindCustomer(t *testing.T) {
	Convey("Given an description (id) and email", t, func() {
		desc, email := "indianajones", "indianajones@gmail.com"

		cust, err := CreateCustomer(desc, email)
		So(err, ShouldBeNil)

		Convey("Then it should create an customer in Stripe", func() {
			custFromStripe, err := stripeCustomer.Get(cust.ProviderCustomerId, nil)

			So(err, ShouldBeNil)
			So(custFromStripe.Id, ShouldEqual, cust.ProviderCustomerId)
		})
	})
}
