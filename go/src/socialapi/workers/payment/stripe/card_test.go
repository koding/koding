package stripe

import (
	"socialapi/workers/payment/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
	stripeToken "github.com/stripe/stripe-go/token"
)

func TestGetCustomerCreditCard(t *testing.T) {
	Convey("Given an existing customer", t, func() {
		tokenParams := &stripe.TokenParams{
			Card: &stripe.CardParams{
				Number: "4012888888881881",
				Month:  "10",
				Year:   "2020",
				Name:   "Indiana Jones",
			},
		}

		token, err := stripeToken.New(tokenParams)
		So(err, ShouldBeNil)

		_, accId, email := generateFakeUserInfo()

		_, err = CreateCustomer(token.Id, accId, email)
		So(err, ShouldBeNil)

		Convey("Then it should be able to get credit card", func() {
			creditCard, err := GetCreditCard(accId)
			So(err, ShouldBeNil)

			So(creditCard.LastFour, ShouldEqual, "1881")
			So(creditCard.Month, ShouldEqual, 10)
			So(creditCard.Year, ShouldEqual, 2020)
			So(creditCard.Name, ShouldEqual, "Indiana Jones")
		})
	})
}

func TestUpdateCustomerCreditCard(t *testing.T) {
	Convey("Given an existing customer", t,
		createCustomerFn(func(accId string, c *paymentmodel.Customer) {
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

				externalCustomer, err := GetCustomerFromStripe(c.ProviderCustomerId)
				So(err, ShouldBeNil)

				So(len(externalCustomer.Cards.Values), ShouldEqual, 1)

				card := externalCustomer.Cards.Values[0]
				So(card.LastFour, ShouldEqual, "1881")
			})
		}),
	)
}

func TestRemoveCreditCard(t *testing.T) {
	Convey("Given an existing customer", t,
		createCustomerFn(func(accId string, c *paymentmodel.Customer) {
			Convey("Then it should be able to remove credit card", func() {
				err := RemoveCreditCard(c)
				So(err, ShouldBeNil)

				externalCustomer, err := GetCustomerFromStripe(c.ProviderCustomerId)
				So(err, ShouldBeNil)

				So(len(externalCustomer.Cards.Values), ShouldEqual, 0)
			})
		}),
	)
}
