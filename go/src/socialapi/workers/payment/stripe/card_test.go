package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
	stripeToken "github.com/stripe/stripe-go/token"
)

func TestUpdateCustomerCreditCard(t *testing.T) {
	Convey("Given an existing customer", t, func() {
		token, accId, email := generateFakeUserInfo()

		customer, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		Convey("Then it should be able to update credit card", func() {
			tokenParams := &stripe.TokenParams{
				Card: &stripe.CardParams{
					Number: "4012888888881881",
					Month:  "10",
					Year:   "20",
				},
			}

			token, err := stripeToken.New(tokenParams)
			So(err, ShouldBeNil)

			err = UpdateCreditCard(accId, token.Id)
			So(err, ShouldBeNil)

			externalCustomer, err := GetCustomerFromStripe(customer.ProviderCustomerId)
			So(err, ShouldBeNil)

			So(len(externalCustomer.Cards.Values), ShouldEqual, 1)

			card := externalCustomer.Cards.Values[0]
			So(card.LastFour, ShouldEqual, "1881")
		})
	})
}
