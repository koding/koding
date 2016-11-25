package payment

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/tests"
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	"github.com/stripe/stripe-go"
)

func TestCheckCustomerHasSource(t *testing.T) {
	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken

		Convey("Given a customer", t, func() {
			withStubData(func(username, groupName, sessionID string) {
				group, err := modelhelper.GetGroup(groupName)
				tests.ResultedWithNoErrorCheck(group, err)

				So(group.Payment.Customer.ID, ShouldNotBeBlank)

				Convey("When customer does not have card", func() {
					has, err := checkCustomerHasSource(group.Payment.Customer.ID)
					Convey("checkCustomerHasSource should return false", func() {
						So(err, ShouldBeNil)
						So(has, ShouldBeFalse)

						Convey("When customer does have card", func() {
							// add credit card to the user
							withTestCreditCardToken(func(token string) {
								// attach payment source
								cp := &stripe.CustomerParams{
									Source: &stripe.SourceParams{
										Token: token,
									},
								}
								c, err := UpdateCustomerForGroup(username, groupName, cp)
								tests.ResultedWithNoErrorCheck(c, err)
								Convey("checkCustomerHasSource should return true", func() {
									has, err := checkCustomerHasSource(group.Payment.Customer.ID)
									So(err, ShouldBeNil)
									So(has, ShouldBeTrue)
								})
							})
						})
					})
				})
			})
		})
	})
}
