package stripe

import (
	"socialapi/workers/payment/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateAndFindCustomer(t *testing.T) {
	Convey("Given a description (id) and email", t,
		createCustomerFn(func(accId string, c *paymentmodel.Customer) {
			Convey("Then it should create an customer in Stripe", func() {
				stripeCustomerId := c.ProviderCustomerId
				So(checkCustomerExistsInStripe(stripeCustomerId), ShouldBeTrue)
			})

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(accId), ShouldBeTrue)
			})
		}),
	)
}
