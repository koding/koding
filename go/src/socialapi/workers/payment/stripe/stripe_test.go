package stripe

import (
	"testing"

	"socialapi/workers/common/runner"

	. "github.com/smartystreets/goconvey/convey"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

func init() {
	r := runner.New("stripetest")
	if err := r.Init(); err != nil {
		panic(err)
	}
}

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

		Convey("Then it should save customer", func() {
			customerModel, err := FindCustomerByUsername(desc)

			So(err, ShouldBeNil)
			So(customerModel.Username, ShouldEqual, desc)
		})
	})
}
